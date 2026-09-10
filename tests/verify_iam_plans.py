"""Run real, fresh-state Terraform plans for the IAM template. Never applies resources."""
import os,sys,json,secrets,shutil,tempfile
from pathlib import Path
BASE=Path(__file__).resolve().parents[1]
from plan_support import run_tf,redact,write_json,plan_summary
workspace=tempfile.TemporaryDirectory(prefix='aiac-iam-plan-')
root=Path(workspace.name)/'project'
shutil.copytree(BASE,root,ignore=shutil.ignore_patterns('.git','.terraform','.aiac','__pycache__','*.tfstate*','*.tfplan','*.tfvars','*.tfvars.json','.env*'))
state=root/'.aiac';(state/'plans').mkdir(parents=True,exist_ok=True)
os.umask(0o077)
os.environ['TF_VAR_initial_passwords']=json.dumps({'employee01':secrets.token_urlsafe(15)+'Aa1!'})
for phase,args in [('init',['init','-backend=false','-input=false','-no-color']),('fmt',['fmt','-check','-recursive','-no-color']),('validate',['validate','-json','-no-color'])]:
 r=run_tf(root,args,180);(state/f'{phase}.log').write_text(redact(r['stdout']+'\n'+r['stderr']))
 print(json.dumps({'stage':phase,'exit_code':r['exit_code']}),flush=True)
 if r['exit_code']: raise SystemExit(1)
prefix='aiac-plan-'+secrets.token_hex(4)
summary=[]
def resource_list(module):
 result=module.get('resources',[])
 for child in module.get('child_modules',[]): result+=resource_list(child)
 return result
for phase in ['onboard','transfer','offboard','remove']:
 user={'user_name':'employee01','display_name':'Example employee','groups':['developers'] if phase=='onboard' else ['operations'],'projects':['alpha'] if phase=='onboard' else ['beta'],'enable_login':True,'enable_access_key':True,'is_offboarding':phase=='offboard'}
 config={'name_prefix':prefix,'environment':'verification','iam_users':[] if phase=='remove' else [user],'project_policy_actions':['vpc:DescribeVpcs','vpc:CreateVpc']}
 params=state/'plans'/f'{phase}.tfvars.json';write_json(params,config)
 plan=state/'plans'/f'{phase}.tfplan'
 r=run_tf(root,['plan','-input=false','-no-color','-detailed-exitcode','-var-file='+str(params),'-out='+str(plan)],180)
 (state/'plans'/f'{phase}.log').write_text(redact(r['stdout']+'\n'+r['stderr']))
 if r['exit_code'] not in [0,2]:
  print(json.dumps({'phase':phase,'exit_code':r['exit_code'],'log':str(state/'plans'/f'{phase}.log')}),flush=True);raise SystemExit(1)
 show=run_tf(root,['show','-json',str(plan)],60)
 data=json.loads(show['stdout']);resources=resource_list(data['planned_values']['root_module'])
 users=[x['values'] for x in resources if x['type']=='volcenginecc_iam_user']
 keys=[x['values'] for x in resources if x['type']=='volcenginecc_iam_accesskey']
 if phase!='remove':
  assert len(users)==len(keys)==1
  expected_group='developers' if phase=='onboard' else ('offboarded' if phase=='offboard' else 'operations')
  assert users[0]['groups']==[prefix+'-'+expected_group],users[0]['groups']
  assert users[0]['login_profile']['login_allowed'] is (phase!='offboard')
  assert users[0]['login_profile']['password_reset_required'] is True
  assert keys[0]['status']==('inactive' if phase=='offboard' else 'active')
 else: assert users==keys==[]
 policies=[x['values'] for x in resources if x['type']=='volcenginecc_iam_policy' and x.get('mode')=='managed']
 for p in policies:
  if p['policy_name'].endswith('-common-read'):
   assert sorted(x['name'] for x in p['policy_user_groups'])==[prefix+'-developers',prefix+'-operations']
  else:
   should_have_user=phase in ['onboard','transfer'] and p['policy_name'].endswith(('-alpha-access' if phase=='onboard' else '-beta-access'))
   bindings=p.get('policy_users') or []
   assert len(bindings)==int(should_have_user),(phase,p['policy_name'],bindings)
   if should_have_user: assert bindings[0]['policy_scope']==[{'project_name':prefix+('-alpha' if phase=='onboard' else '-beta')}]
 item={'phase':phase,'status':'passed','plan':plan_summary(data),'checks':['group membership','project scoped bindings','login disabled on offboard','forced password reset','key disabled on offboard','resource cardinality']}
 summary.append(item);print(json.dumps({'phase':phase,'status':item['status'],'totals':item['plan']['totals']},ensure_ascii=False),flush=True)
 plan.unlink(missing_ok=True)
write_json(state/'plan-matrix.json',summary)

output=BASE/'.aiac/iam-plan-matrix.json'
write_json(output,summary)
print('Plan-only test report:',output)
workspace.cleanup()

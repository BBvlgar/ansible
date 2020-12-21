# Testing
To test if create user is working, run it in the ```testing``` environment and use the production JIRA (AM-36 = test user) as the input source.
```
ansible-playbook -i environments/testing roles/create_user/tasks/main.yml -e "env=testing admin_user=fbuchmeier admin_password=$password ticket_user=fbuchmeier ticket_url=https://jira.it-economics.de"
```

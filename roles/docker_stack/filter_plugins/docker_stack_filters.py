#!/usr/bin/env python3
class FilterModule(object):

    def filters(self):
        return {
            'prepareContainerNames': self.prepareContainerNames,
            'preparestring': self.prepareString,
            'preparestack': self.prepareStack,
            'prepareSharedHome': self.prepareSharedHome,
            'prepareDataContainer': self.prepareDataContainer,
            'unifyVolumes': self.unifyVolumes,
            'ensurePullRun': self.ensurePullRun,
            'adjustNetworks': self.adjustNetworks,
        }

    def prepareString(self, line):
        line = line.lower()
        chars = {
            'ä': 'ae',
            'æ': 'ae',
            'ö': 'oe',
            'ü': 'ue',
            'ß': 'ss',
        }
        for char in chars:
            line = line.replace(char,chars[char])
        line = line.replace(' ', '-')
        return line

    def prepareStack(self, stack):
        newStack = stack
        newStack['name'] = self.prepareString(stack['name'])
        return newStack

    def prepareContainerNames(self, stack_items, stack):
        for i, cnt in enumerate(stack_items):
            new_name = stack['name'] + '_' + cnt['name']
            stack_items[i]['name'] = self.prepareString(new_name)
        return stack_items

    def prepareSharedHome(self, stack_items, stackname):
        for i, cnt in enumerate(stack_items):
            if 'shared_home_app' not in stack_items[i]:
                stack_items[i]['shared_home_app'] = stackname
                if stack_items[i]['name'] != 'data':
                    iterators = [
                        "directories",
                        "directories_no_backup",
                        "mountfiles",
                        "mountfiles_no_backup",
                    ]
                    for k in iterators:
                        if k in cnt:
                            for j in range( len( stack_items[i][k] ) ):
                                stack_items[i][k][j][0][0] = self.prepareString( stack_items[i]['name'] ) + '/' + stack_items[i][k][j][0][0]
        return stack_items

    def prepareDataContainer(self, stack_items, stackname, stack_data={} ):

        mandatoryKeys = [
            "directories",
            "mountfiles",
            "volumes",
        ]
        for k in mandatoryKeys:
            if k not in stack_data:
                stack_data[k] = []

        for cnt in stack_items:
            backup_prefix = '/backup/' + stackname + '/' + self.prepareString( cnt['name'] ) + '/'
            print(cnt)
            print()
            if "directories" in cnt:
                helper = cnt['directories']
                for i in range( len( helper ) ):
                    if helper[i][0][1][0] == '/':
                        helper[i][0][1] = helper[i][0][1][1:]
                    helper[i][0][1] = backup_prefix + 'directories/' + helper[i][0][1]
                stack_data['directories'] = stack_data['directories'] + helper
            if "mountfiles" in cnt:
                helper = cnt['mountfiles']
                for i in range( len( helper ) ):
                    if helper[i][0][1][0] == '/':
                        helper[i][0][1] = helper[i][0][1][1:]
                    helper[i][0][1] = backup_prefix + 'mountfiles/' + helper[i][0][1]
                stack_data['mountfiles']  = stack_data['mountfiles'] + helper
            if "volumes" in cnt:
                helper = cnt['volumes']
                for i in range( len( helper ) ):
                    vol = helper[i].split(':')
                    if vol[1][0] == '/':
                        vol[1] = vol[1][1:]
                    vol[1] = backup_prefix + 'volumes/' + vol[1]
                    helper[i] = ':'.join(vol)
                    # print(helper[i])
                stack_data['volumes']     = stack_data['volumes'] + helper
        return stack_data

    def unifyVolumes(self, stack_items):
        for i, cnt in enumerate(stack_items):
            if "directories_no_backup" in cnt:
                if "directories" not in cnt:
                    cnt['directories'] = []
                stack_items[i]['directories'] = cnt['directories'] + cnt['directories_no_backup']
                stack_items[i].pop('directories_no_backup', None)
            if "mountfiles_no_backup" in cnt:
                if "mountfiles" not in cnt:
                    cnt['mountfiles'] = []
                stack_items[i]['mountfiles'] = cnt['mountfiles'] + cnt['mountfiles_no_backup']
                stack_items[i].pop('mountfiles_no_backup', None)
            if "volumes_no_backup" in cnt:
                if "volumes" not in cnt:
                    cnt['volumes'] = []
                stack_items[i]['volumes'] = cnt['volumes'] + cnt['volumes_no_backup']
                stack_items[i].pop('volumes_no_backup', None)
        return stack_items

    def ensurePullRun(self, stack_items):
        for i, cnt in enumerate(stack_items):
            if "run" not in cnt:
                stack_items[i]['run'] = True
            if "pull" not in cnt:
                stack_items[i]['pull'] = True
        return stack_items

    def adjustNetworks(self, stack_items):
        for i, cnt in enumerate(stack_items):
            if "networks" in cnt:
                networks = stack_items[i]['networks']
                stack_items[i]['networks'] = []
                for network in networks:
                    if isinstance(network, str) :
                        stack_items[i]['networks'].append( { 'name': network } )
                    elif isinstance(network, dict) and network.__contains__( 'name' ):
                        stack_items[i]['networks'].append( network )
        return stack_items

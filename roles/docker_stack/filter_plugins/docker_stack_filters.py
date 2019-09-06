#!/usr/bin/python
class FilterModule(object):
    def filters(self):
        return {
            'stackcontainername': self.stackContainerName
        }

    def stackContainerName(self, container_dict, container_name, stack):
        new_name = stack['name'] + '_' + container_name
        container_dict['name'] = new_name
        return container_dict

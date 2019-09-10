#!/usr/bin/env python3
class FilterModule(object):

    def filters(self):
        return {
            'stackcontainername': self.stackContainerName,
            'preparestring': self.prepareString,
        }

    def prepareString(self, line):
        line = line.lower()
        chars = { 'ä': 'ae', 'æ': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss', }
        for char in chars:
            line = line.replace(char,chars[char])
        line = line.replace(' ', '-')
        return line

    def stackContainerName(self, container_dict, container_name, stack):
        new_name = stack['name'] + '_' + container_name
        container_dict['name'] = self.prepareString(new_name)
        return container_dict

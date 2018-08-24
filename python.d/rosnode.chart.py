#from bases.FrameworkServices.SimpleService import SimpleService

from bases.FrameworkServices.ExecutableService import ExecutableService

# default module values (can be overridden per job in `config`)
#update_every = 4
priority = 90000
retries = 60

# charts order (can be overridden if you want less charts, or different order)
ORDER = ['nodes_number', 'nodes_name','nodes_info']

# If you can not determine the charts now, you can update the CHARTS anytime you want just like the code below.
# Update a chart (if the chart exists, ignore the next line.)
# CHARTS[id] = dict()                                                          
# CHARTS[id]['options'] = [name, title, units, family, context, charttype]
# CHARTS[id]['lines'] = [ [id, name, algorithm, multiplier, divisor], ..., [...], ]
# CHARTS[id]['variables'] = [ [id], ...,]

# Add a dimension
# CHARTS[id]['lines'].append([id, name, algorithm, multiplier, divisor])

# CHARTS[id]['variables'].append([id])

CHARTS = {
    # id: {
    #     'options': [name, title, units, family, context, charttype],
    #     'lines': [
    #         [id, name, algorithm, multiplier, divisor]
    #     ]
    #     (option)
    #     'variables': [
    #         [id]
    #     ]}
    'nodes_number': {
        'options': [None, 'The total number of nodes', 'amount', 'rosnode', 'rosnode.number', 'line'],
        'lines': [
            ['nodesnumber', None, 'absolute', 1, 1],
        ],
    },
    'nodes_name': {
        'options': [None, 'Name of nodes', 'names', 'rosnode', 'rosnode.name', 'string'],
        'lines': [
            ['nodesname', None],
        ],
    },
    'nodes_info': {
        'options': [None, 'Info of nodes', 'info', 'rosnode', 'rosnode.info', 'string'],
        'lines': [
            ['nodesinfo', None],
        ],
    },
}

class Service(ExecutableService):
    def __init__(self, configuration=None, name=None):
        ExecutableService.__init__(self, configuration=configuration, name=name)
        self.order = ORDER

        # All the commands should be run. First command must be complete, others may add arguments from provious commands.
        self.commands_base = ['rosnode list','rosnode info']
        
    def _get_data(self):
        data = dict()
        # For each command, you need to design two functions: pre_process and post_process.
        # In the function pre_process, you should return the complete command finally.
        def rosnode_list_pre_process(command):
            return command

        # In the function post_process, you need to fill the dict by proper key-value 
        # An easy way to do that is to assign value for each dimension in charts like
        # data[dimension_id] = value
        def rosnode_list_post_process(raw_data):
            if(raw_data):
                data['nodesnumber'] = len(raw_data)
                data['nodesname'] = raw_data[0][:-1]
                for each_node_name in raw_data[1:] :
                    data['nodesname'] = data['nodesname'] + ' '
                    data['nodesname'] = data['nodesname'] + each_node_name[:-1]
            else:
                data['nodesnumber'] = 0

        def rosnode_info_pre_process(command):
            if data['nodesnumber'] == 0:
                command = None
            else:
                command = str(command + ' ' + data['nodesname'])
            return command

        def rosnode_info_post_process(raw_data):
            data['nodesinfo'] = ''
            for info_line in raw_data :
                data['nodesinfo'] = data['nodesinfo'] + info_line.replace('\n', ' ')

        for command in self.commands_base:
            self.command = locals()[command.replace(' ', '_') + '_pre_process'](command)
            # Check whether a command is reasonable.
            if(command and self.check_a_command()):
                raw_data = self._get_raw_data()
                locals()[command.replace(' ', '_') + '_post_process'](raw_data)

        # Not allow to update CHARTS anymore
        self.definitions = CHARTS
        return data
        

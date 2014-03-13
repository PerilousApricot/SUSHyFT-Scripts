# CRAB2JobParser - accepts an xml file, makes a usable class out of it
import pprint
import xml.dom.minidom

class CRAB2JobParser:
    def __init__(self, inputFile):
        doc = xml.dom.minidom.parse(inputFile)
        task = doc.getElementsByTagName('Task')[0]
        taskAttributes = task.getElementsByTagName('TaskAttributes')[0]
        importantTaskAttributes=['dataset','name','outputDirectory']
        for k in importantTaskAttributes:
            setattr(self, k, taskAttributes.getAttribute(k))
        jobs = task.getElementsByTagName('TaskJobs')[0]
        self.jobs = {}
        for job in jobs.getElementsByTagName('Job'):
            currJob = {}
            importantAttributes = ['jobId', 'closed']
            for k in importantAttributes:
                currJob[k] = job.getAttribute(k)

            runningJob = job.getElementsByTagName('RunningJob')
            if runningJob:
                runningJob = runningJob[0]
                importantAttributes = ['applicationReturnCode',
                                       'processStatus',
                                       'schedulerId',
                                       'state',
                                       'status',
                                       'statusScheduler',
                                       'wrapperReturnCode']
                for k in importantAttributes:
                    if runningJob.hasAttribute(k):
                        currJob[k] = runningJob.getAttribute(k)
            self.jobs[currJob['jobId']] = currJob
        pprint.pprint(self.jobs)




d = CRAB2JobParser('data/auto_edntuple/crab_v2_ZZJetsTo4L_TuneZ2star_8TeV-madgraph-tauola/share/machine.xml')

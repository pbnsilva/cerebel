from setuptools import setup, find_packages

setup(name='cerebel',
      version='0.1',
      description="Cerebel ML toolbox",
      author='Pedro Silva',
      author_email='pedro@cerebel.io',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False)

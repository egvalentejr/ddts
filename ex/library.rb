module Library

  # REQUIRED METHODS (CALLED BY DRIVER)

  def lib_build(env)
    bindir=env.build.bindir
    binname=env.run.binname
    compiler=env.build.compiler
    srcdir=env.build.ddts_root
    srcfile=env.build.srcfile
    cmd="cd #{srcdir} && #{compiler} #{srcfile} -o #{bindir}/#{binname}"
    ext(cmd,{:msg=>"Build failed, see #{logfile}"})
  end

  def lib_build_post(env,buildkit)
    File.join(env.build.ddts_root,env.build.bindir,env.build.binname)
  end

  def lib_build_prep(env)
    FileUtils.cp(File.join(app_dir,env.build.srcfile),env.build.ddts_root)
    FileUtils.mkdir_p(File.join(env.build.ddts_root,env.build.bindir))
  end

  def lib_outfiles_ex(env,path)
    expr=File.join(path,'out[0-9]')
    Dir.glob(expr).map { |e| [path,File.basename(e)] }
  end

  def lib_comp_alt(env,f1,f2)
    logi "Comparing '#{f1}' to '#{f2}' with alternate comparator..."
    FileUtils.compare_file(f1,f2)
  end

  def lib_data(env)
    f="data.tgz"
    src=File.join(app_dir,f)
    dst=File.join(tmp_dir,f)
    cmd="cp #{src} #{dst}"
    md5='d49037f1ef796b8a7ca3906e713fc33b'
    unless File.exists?(dst) and hash_matches(dst,md5)
      logd "Getting data: #{cmd}"
      output,status=ext(cmd,{:msg=>"Failed to get data, see #{logfile}"})
      die "Data archive #{f} has incorrect md5 hash" unless hash_matches(dst,md5)
    end
    logd "Data archive #{f} ready"
    cmd="cd #{tmp_dir} && tar xvzf #{f}"
    logd "Extracting data: #{cmd}"
    output,status=ext(cmd,{:msg=>"Data extract failed, see #{logfile}"})
    logd "Data extract complete"
  end

  def lib_run(env,rundir)
    bin=env.run.binname
    run=env.run.runcmd
    sleep=env.run.sleep
    tasks=env.run.tasks
    if message=env.run.message
      logi message.join(" ")
    end
    cmd="cd #{rundir} && #{run} #{tasks} #{bin} >stdout 2>&1 && sleep #{sleep}"
    IO.popen(cmd) { |io| io.readlines.each { |e| logd "#{e}" } }
    File.join(rundir,'stdout')
  end

  def lib_run_check(env,postkit)
    unless (stdout=File.open(postkit).read)=~/SUCCESS/
      stdout.each_line { |line| logi line.chomp }
    end
    (job_check(postkit,"SUCCESS"))?(true):(false)
  end

  def lib_run_post(env,runkit)
    runkit
  end

  def lib_run_prep(env,rundir)
    binname=env.run.binname
    conffile=env.run.conffile
    FileUtils.cp(env.build.ddts_result,rundir)
    FileUtils.chmod(0755,File.join(rundir,binname))
    a=env.run.a
    b=env.run.b
    n=env.run.n||0
    confstr="&config a=#{a} b=#{b} n=#{n} /\n"
    conffile=File.join(rundir,env.run.conffile)
    File.open(conffile,'w') { |f| f.write(confstr) }
    rundir
  end

  def lib_suite_post(env)
    logi "[ default post action ]"
  end

  def lib_suite_post_ex(env)
    buildfails=env.suite.ddts_builds.reduce(0) { |m,(k,v)| (v.failed)?(m+1):(m) }
    logi "build fail rate = #{Float(buildfails)/env.suite.ddts_builds.size}"
    runfails=env.suite.ddts_runs.reduce(0) { |m,(k,v)| (v.failed)?(m+1):(m) }
    logi "run fail rate = #{Float(runfails)/env.suite.ddts_runs.size}"
    logi "[ custom post action ]"
  end

  def lib_suite_prep(env)
    logi "[ default prep action ]"
  end

  def lib_suite_prep_ex(env)
    logi "[ custom prep action ]"
  end

  # CUSTOM METHODS (NOT CALLED BY DRIVER)

end

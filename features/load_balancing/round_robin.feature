# encoding: utf-8

@wip
Feature: Round Robin Policy

  The Round Robin load balancing policy dispatches requests evenly on cluster
  nodes.

  The effects of the policy can be seen by enabling requests tracing. The
  coordinator node that served every traced request can be retrieved from the
  system_traces.session table.

  Scenario: the default load balancing policy is Round Robin
    Given a cassandra cluster with schema "simplex" with table "songs"
    And the following example:
      """ruby
      require 'cql'

      cluster = Cql.cluster().build
      session = cluster.connect('simplex')

      results_1 = session.execute("SELECT * FROM songs", :trace => true)
      results_2 = session.execute("SELECT * FROM songs", :trace => true)
      results_3 = session.execute("SELECT * FROM songs", :trace => true)

      coordinators = session.execute(
        "SELECT coordinator
         FROM system_traces.sessions
         WHERE session_id IN (?, ?, ?)",
         results_1.trace_id,
         results_2.trace_id,
         results_3.trace_id
      )
      ips = coordinators.map do |row|
        row["coordinator"].to_s
      end

      puts ips.sort
      """
    When it is executed
    Then its output should contain:
      """
      127.0.0.1
      127.0.0.2
      127.0.0.3
      """

  Scenario: An explicit Round Robin policy can also explicitely be used
    Given a cassandra cluster with schema "simplex" with table "songs"
    And the following example:
      """ruby
      require 'cql'

      cluster = Cql.cluster()
      .with_load_balancing_policy(Cql::LoadBalancing::Policies::RoundRobin.new)
        .build
      session = cluster.connect('simplex')

      results_1 = session.execute("SELECT * FROM songs", :trace => true)
      results_2 = session.execute("SELECT * FROM songs", :trace => true)
      results_3 = session.execute("SELECT * FROM songs", :trace => true)

      coordinators = session.execute(
        "SELECT coordinator
         FROM system_traces.sessions
         WHERE session_id IN (?, ?, ?)",
         results_1.trace_id,
         results_2.trace_id,
         results_3.trace_id
      )
      ips = coordinators.map do |row|
        row["coordinator"].to_s
      end

      puts ips.sort
      """
    When it is executed
    Then its output should contain:
      """
      127.0.0.1
      127.0.0.2
      127.0.0.3
      """

  Scenario: The Round Robin policy is unaware of multi-datacenter clusters
    Given a 2x2-nodes running cassandra cluster with schema "simplex" with table "songs"
    And the following example:
    """ruby
      require 'cql'

      cluster = Cql.cluster()
        .with_load_balancing_policy(Cql::LoadBalancing::Policies::RoundRobin.new)
        .build
      session = cluster.connect('simplex')

      trace_ids = []
      4.times do
        trace_ids.push session.execute("SELECT * FROM songs", :trace => true).trace_id.to_s
      end

      coordinators = session.execute(
        "SELECT coordinator
         FROM system_traces.sessions
         WHERE session_id IN (#{trace_ids.join(",")})"
      )
      ips = coordinators.map do |row|
        row["coordinator"].to_s
      end

      puts ips.sort
      """
    When it is executed
    Then its output should contain:
      """
      127.0.0.1
      127.0.0.2
      127.0.0.3
      127.0.0.4
      """

  @todo
  Scenario: The Datacenter-aware Round Robin policy is aware of multi-datacenter clusters
    Given a 2x2-nodes running cassandra cluster with schema "simplex" with table "songs"
    And the following example:
    """ruby
      require 'cql'

      cluster = Cql.cluster()
        .with_load_balancing_policy(Cql::LoadBalancing::Policies::DCAwareRoundRobin.new("dc2"))
        .build
      session = cluster.connect('simplex')

      trace_ids = []
      4.times do
        trace_ids.push session.execute("SELECT * FROM songs", :trace => true).trace_id.to_s
      end

      coordinators = session.execute(
        "SELECT coordinator
         FROM system_traces.sessions
         WHERE session_id IN (#{trace_ids.join(",")})"
      )
      ips = coordinators.map do |row|
        row["coordinator"].to_s
      end

      puts ips.sort
      """
    When it is executed
    Then its output should contain:
    """
      127.0.1.3
      127.0.1.4
      """

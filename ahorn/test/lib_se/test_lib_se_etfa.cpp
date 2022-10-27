#define SPDLOG_ACTIVE_LEVEL SPDLOG_LEVEL_TRACE

#include <gtest/gtest.h>

#include "cfg/builder.h"
#include "cfg/cfg.h"
#include "compiler/compiler.h"
#include "pass/decision_transformation_pass.h"
#include "se/configuration.h"
#include "se/etfa-no-merge/engine.h"
#include "se/etfa/engine.h"
#include "se/reuse/engine.h"
#include "se/summarization/engine.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/sinks/basic_file_sink.h"
#include "spdlog/sinks/stdout_color_sinks.h"
#include "spdlog/spdlog.h"

#include <fstream>

class TestLibSeETFA : public ::testing::Test {
public:
    TestLibSeETFA() : ::testing::Test() {}

protected:
    void SetUp() override {
        createLogger("ETFA");
        createLogger("Summarization");
        createLogger("Reuse");
    }

    void createLogger(const std::string &name) {
        auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        console_sink->set_level(spdlog::level::trace);

        auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>("logs/" + name + ".txt", true);
        file_sink->set_level(spdlog::level::trace);

        std::vector<spdlog::sink_ptr> sinks;
        sinks.push_back(console_sink);
        sinks.push_back(file_sink);

        auto logger = std::make_shared<spdlog::logger>(name, std::begin(sinks), std::end(sinks));
        logger->set_level(spdlog::level::info);

        spdlog::register_logger(logger);
    }

    void TearDown() override {
        spdlog::drop("ETFA");
        spdlog::drop("Summarization");
        spdlog::drop("Reuse");
    }

    static std::shared_ptr<Cfg> getCfg(std::string const &path) {
        std::ifstream file(path);
        std::stringstream buffer;
        buffer << file.rdbuf();
        file.close();
        const std::string &source_code = buffer.str();
        auto project = Compiler::compile(source_code);
        auto builder = std::make_unique<Builder>(*project);
        return builder->build();
    }
};

TEST_F(TestLibSeETFA, 01) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/01/01_old.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);
    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/benchmark/etfa/01/01_cap.st");
    std::shared_ptr<Cfg> transformed_new_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_new_cfg = decision_transformation_pass->apply(*new_cfg);
        std::cout << transformed_new_cfg->toDot() << std::endl;
    }

    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());
    // Phase 3 - Reuse summaries across program versions
    se::summarization::Summarizer &summarizer = summarization_engine->getSummarizer();
    std::shared_ptr<se::summarization::Summarizer> valid_summarizer =
            reuse_engine->run(*transformed_new_cfg, summarizer);
    // Phase 4 - Execute program with reusable summaries
    engine->run(*valid_summarizer, *transformed_new_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, 02) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/02/02_old.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_cycle_bound = 100;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);
    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/benchmark/etfa/02/02_cap.st");
    std::shared_ptr<Cfg> transformed_new_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_new_cfg = decision_transformation_pass->apply(*new_cfg);
        std::cout << transformed_new_cfg->toDot() << std::endl;
    }

    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());
    // Phase 3 - Reuse summaries across program versions
    se::summarization::Summarizer &summarizer = summarization_engine->getSummarizer();
    std::shared_ptr<se::summarization::Summarizer> valid_summarizer =
            reuse_engine->run(*transformed_new_cfg, summarizer);
    // Phase 4 - Execute program with reusable summaries
    engine->run(*valid_summarizer, *transformed_new_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, 03) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/03/03_old.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_cycle_bound = 100;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);
    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/benchmark/etfa/03/03_cap.st");
    std::shared_ptr<Cfg> transformed_new_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_new_cfg = decision_transformation_pass->apply(*new_cfg);
        std::cout << transformed_new_cfg->toDot() << std::endl;
    }

    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());
    // Phase 3 - Reuse summaries across program versions
    se::summarization::Summarizer &summarizer = summarization_engine->getSummarizer();
    std::shared_ptr<se::summarization::Summarizer> valid_summarizer =
            reuse_engine->run(*transformed_new_cfg, summarizer);
    // Phase 4 - Execute program with reusable summaries
    engine->run(*valid_summarizer, *transformed_new_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Call_Coverage_In_3_Cycles) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/lib_se/file/call_coverage_in_3_cycles.st");
    std::cout << cfg->toDot() << std::endl;
    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Multiple_Fb_Call_Coverage_In_3_Cycles) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/lib_se/file/multiple_fb_call_coverage_in_3_cycles.st");
    std::cout << cfg->toDot() << std::endl;
    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Call_Coverage_In_3_Cycles_Unchanged) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/lib_se/file/call_coverage_in_3_cycles.st");
    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/lib_se/file/call_coverage_in_3_cycles_with_change_annotation"
                                          ".st");
    std::cout << new_cfg->toDot() << std::endl;

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *old_cfg);

    // Phase 3 - Reuse summaries across program versions
    auto &summarizer = summarization_engine->getSummarizer();
    reuse_engine->run(*new_cfg, summarizer);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Call_Coverage_In_2_Cycles) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/lib_se/file/call_coverage_in_3_cycles.st");
    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/lib_se/file/call_coverage_in_2_cycles_with_change_annotation.st");
    std::cout << new_cfg->toDot() << std::endl;

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *old_cfg);

    // Phase 3 - Reuse summaries across program versions
    auto &summarizer = summarization_engine->getSummarizer();
    reuse_engine->run(*new_cfg, summarizer);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SF_Antivalent) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/benchmark/dissertation/PLCopen_safety/SFAntivalent.st");
    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Test) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/old_test.st");
    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/benchmark/etfa/new_test.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    std::shared_ptr<Cfg> transformed_new_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_new_cfg = decision_transformation_pass->apply(*new_cfg);
        std::cout << transformed_new_cfg->toDot() << std::endl;
    }


    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    // Phase 3 - Reuse summaries across program versions
    auto &summarizer = summarization_engine->getSummarizer();
    reuse_engine->run(*transformed_new_cfg, summarizer);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, EmergencyStopTest) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/old_emergency_stop_test.st");
    std::shared_ptr<Cfg> new_cfg = getCfg("../../test/benchmark/etfa/new_emergency_stop_test.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    std::shared_ptr<Cfg> transformed_new_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_new_cfg = decision_transformation_pass->apply(*new_cfg);
        std::cout << transformed_new_cfg->toDot() << std::endl;
    }


    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->_cycle_bound = 1;
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    // Phase 3 - Reuse summaries across program versions
    auto &summarizer = summarization_engine->getSummarizer();
    reuse_engine->run(*transformed_new_cfg, summarizer);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFAntivalentTest) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFAntivalent.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_cycle_bound = 15;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFEDMTest) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFEDM.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFGuardLockingTest) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFGuardLocking.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFModeSelectorTest) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFModeSelector.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFSafelyLimitSpeed) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFSafelyLimitSpeed.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFSafelyLimitSpeed_Concolic_No_Merge) {
    using namespace se::etfa_no_merge;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFSafelyLimitSpeed.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    std::unique_ptr<se::Configuration> configuration = std::make_unique<se::Configuration>();
    configuration->_no_merge = true;
    configuration->_cycle_bound = 5;

    auto engine = std::make_unique<se::etfa_no_merge::Engine>(std::move(configuration));
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    std::cout << "Phase 1 - Generating summaries:" << std::endl;
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    std::cout << "Phase 2 - Executing old program:" << std::endl;
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SFSafeStop_Concolic_No_Merge) {
    using namespace se::etfa_no_merge;
    std::shared_ptr<Cfg> old_cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFSafeStop.st");
    std::shared_ptr<Cfg> transformed_old_cfg;
    {
        auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
        transformed_old_cfg = decision_transformation_pass->apply(*old_cfg);
    }

    std::unique_ptr<se::Configuration> configuration = std::make_unique<se::Configuration>();
    configuration->_no_merge = true;
    configuration->_cycle_bound = 5;

    auto engine = std::make_unique<se::etfa_no_merge::Engine>(std::move(configuration));
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());

    // Phase 1 - Generate summaries
    std::cout << "Phase 1 - Generating summaries:" << std::endl;
    summarization_engine->run(*transformed_old_cfg);

    // Phase 2 - Execute program
    std::cout << "Phase 2 - Executing old program:" << std::endl;
    engine->run(summarization_engine->getSummarizer(), *transformed_old_cfg);

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, Call_Summary_PC) {
    using namespace se::etfa;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/lib_se/file/call_summary_pc.st");
    auto decision_transformation_pass = std::make_unique<pass::DecisionTransformationPass>();
    std::shared_ptr<Cfg> transformed_cfg = decision_transformation_pass->apply(*cfg);
    auto engine = std::make_unique<Engine>(std::make_unique<se::Configuration>());
    auto summarization_engine = std::make_unique<se::summarization::Engine>(engine->getSolver());
    auto reuse_engine = std::make_unique<se::reuse::Engine>(engine->getSolver());
    // Phase 1 - Generate summaries
    summarization_engine->run(*transformed_cfg);
    // Phase 2 - Execute program
    engine->run(summarization_engine->getSummarizer(), *transformed_cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFA, SummaryExperiment) {
    z3::context ctx;
    z3::expr x_0 = ctx.int_const("x_0");
    z3::expr y_0 = ctx.int_const("y_0");
    z3::expr s_1 = (x_0 >= 32) && ((y_0 + 1) >= 3);

    // current context
    z3::model m(ctx);
    z3::func_decl x_0_decl = x_0.decl();
    z3::func_decl y_0_decl = y_0.decl();
    z3::expr const_2 = ctx.int_val(2);
    m.add_const_interp(x_0_decl, x_0);
    m.add_const_interp(y_0_decl, const_2);

    // eval summary under current context instead of checking summary
    z3::expr r = m.eval(s_1, true);
    std::cout << r.to_string() << std::endl;

    ASSERT_EQ(0, 1);
}

/*
 * Call_Coverage_In_2_Cycles - Checking whether predicateSensitiveAnalysis behaves as intended.
 * Important: Used in Dissertation as running example!
 */
TEST_F(TestLibSeETFA, PredicateSensitiveChangeImpactAnalysis) {
    z3::context ctx;

    // Boolean assumption literals
    z3::expr b_0 = ctx.bool_const("b_0");
    z3::expr b_1 = ctx.bool_const("b_1");
    z3::expr b_2 = ctx.bool_const("b_2");
    z3::expr b_4 = ctx.bool_const("b_4");
    z3::expr b_6 = ctx.bool_const("b_6");
    z3::expr b_7 = ctx.bool_const("b_7");
    z3::expr b_9 = ctx.bool_const("b_9");
    z3::expr b_11 = ctx.bool_const("b_11");
    z3::expr b_13 = ctx.bool_const("b_13");

    // Flow of control
    z3::expr_vector flow(ctx);
    flow.push_back(z3::implies(b_0, ctx.bool_val(true)));
    flow.push_back(z3::implies(b_1, b_0));
    flow.push_back(z3::implies(b_2, b_1));
    flow.push_back(z3::implies(b_4, b_1));
    flow.push_back(z3::implies(b_6, b_2 || b_4));
    flow.push_back(z3::implies(b_7, b_6));
    flow.push_back(z3::implies(b_9, b_7));
    flow.push_back(z3::implies(b_11, b_6));
    flow.push_back(z3::implies(b_13, b_9 || b_11));

    // Variables
    z3::expr x_0 = ctx.int_const("x_0");
    z3::expr y_0 = ctx.int_const("y_0");
    z3::expr y_1 = ctx.int_const("y_1");
    z3::expr y_2 = ctx.int_const("y_2");
    z3::expr y_3 = ctx.int_const("y_3");
    z3::expr y_4 = ctx.int_const("y_4");
    z3::expr y_5 = ctx.int_const("y_5");
    z3::expr z_0 = ctx.bool_const("z_0");
    z3::expr z_1 = ctx.bool_const("z_1");
    z3::expr z_2 = ctx.bool_const("z_2");
    z3::expr z_3 = ctx.bool_const("z_3");

    // Hard constraints
    z3::expr_vector hard_constraints(ctx);
    hard_constraints.push_back(z3::implies(b_2, (y_2 == y_0 + 1) && (y_3 == y_2)));
    hard_constraints.push_back(z3::implies(b_4, (y_1 == y_0) && (y_3 == y_1)));
    hard_constraints.push_back(z3::implies(b_7, (z_2 == ctx.bool_val(true))));
    hard_constraints.push_back(z3::implies(b_9, (y_4 == 0) && (y_5 == y_4) && (z_3 == z_2)));
    hard_constraints.push_back(z3::implies(b_11, (y_5 == y_3) && (z_1 == ctx.bool_val(false)) && (z_3 == z_1)));

    // Assumptions
    z3::expr_vector assumptions(ctx);
    assumptions.push_back(z3::implies(b_2, (x_0 >= 32)));
    assumptions.push_back(z3::implies(b_4, !(x_0 >= 32)));
    assumptions.push_back(z3::implies(b_7, (y_3 >= 3)));
    assumptions.push_back(z3::implies(b_11, !(y_3 >= 3)));

    // Instrumentation
    z3::expr_vector instrumentation(ctx);
    z3::expr reconfigured_0 = ctx.bool_const("reconfigured_0");
    z3::expr reconfigured_1 = ctx.bool_const("reconfigured_1");
    z3::expr reconfigured_2 = ctx.bool_const("reconfigured_2");
    z3::expr P = ctx.bool_const("P");
    z3::expr Q = ctx.bool_const("Q");
    instrumentation.push_back(z3::implies(b_0, (reconfigured_0 == ctx.bool_val(false))));
    instrumentation.push_back(
            z3::implies(b_2, (reconfigured_1 == ctx.bool_val(true)) && (reconfigured_2 == reconfigured_1)));
    instrumentation.push_back(z3::implies(b_4, (reconfigured_2 == reconfigured_0)));
    instrumentation.push_back(z3::implies(b_13, (z3::implies(Q, !(reconfigured_2)))));
    instrumentation.push_back(z3::implies(P, (x_0 >= 32) && (!(y_0 >= 2))));
    instrumentation.push_back(z3::implies(Q, (y_5 == (y_0 + 1)) && (z_3 == ctx.bool_val(false))));

    // Solver
    z3::solver solver(ctx);
    solver.add(flow);
    solver.add(hard_constraints);
    solver.add(assumptions);
    solver.add(instrumentation);

    // Assumption literals for incremental solving
    z3::expr_vector assumption_literals(ctx);
    // enforce that the predicate P, implying the assumptions of the summary, is always true
    assumption_literals.push_back(P);
    // enforce that the predicate Q, implying the hard constraints of the summary, is always true
    assumption_literals.push_back(Q);
    // enforce that exit location of fb is reachable
    assumption_literals.push_back(b_13);
    // check under assumptions
    z3::check_result check_result = solver.check(assumption_literals);
    switch (check_result) {
        case z3::unsat: {
            std::cout << "UNSAT" << std::endl;
            z3::expr_vector unsat_core = solver.unsat_core();
            std::cout << unsat_core << std::endl;
            break;
        }
        case z3::sat: {
            std::cout << "SAT" << std::endl;
            z3::model model = solver.get_model();
            std::cout << model << std::endl;
            break;
        }
        case z3::unknown:
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }

    ASSERT_EQ(0, 1);
}

/*
 * Call_Coverage_In_2_Cycles - Checking whether validityChecking behaves as intended.
 * Important: Used in Dissertation as running example!
 */
TEST_F(TestLibSeETFA, MustSummaryValidityChecking) {
    z3::context ctx;

    // Boolean assumption literals
    z3::expr b_0 = ctx.bool_const("b_0");
    z3::expr b_1 = ctx.bool_const("b_1");
    z3::expr b_2 = ctx.bool_const("b_2");
    z3::expr b_4 = ctx.bool_const("b_4");
    z3::expr b_6 = ctx.bool_const("b_6");
    z3::expr b_7 = ctx.bool_const("b_7");
    z3::expr b_9 = ctx.bool_const("b_9");
    z3::expr b_11 = ctx.bool_const("b_11");
    z3::expr b_13 = ctx.bool_const("b_13");

    // Flow of control
    z3::expr_vector flow(ctx);
    flow.push_back(z3::implies(b_0, ctx.bool_val(true)));
    flow.push_back(z3::implies(b_1, b_0));
    flow.push_back(z3::implies(b_2, b_1));
    flow.push_back(z3::implies(b_4, b_1));
    flow.push_back(z3::implies(b_6, b_2 || b_4));
    flow.push_back(z3::implies(b_7, b_6));
    flow.push_back(z3::implies(b_9, b_7));
    flow.push_back(z3::implies(b_11, b_6));
    flow.push_back(z3::implies(b_13, b_9 || b_11));

    // Variables
    z3::expr x_0 = ctx.int_const("x_0");
    z3::expr y_0 = ctx.int_const("y_0");
    z3::expr y_1 = ctx.int_const("y_1");
    z3::expr y_2 = ctx.int_const("y_2");
    z3::expr y_3 = ctx.int_const("y_3");
    z3::expr y_4 = ctx.int_const("y_4");
    z3::expr y_5 = ctx.int_const("y_5");
    z3::expr z_0 = ctx.bool_const("z_0");
    z3::expr z_1 = ctx.bool_const("z_1");
    z3::expr z_2 = ctx.bool_const("z_2");
    z3::expr z_3 = ctx.bool_const("z_3");

    // Hard constraints
    z3::expr_vector hard_constraints(ctx);
    hard_constraints.push_back(z3::implies(b_2, (y_2 == y_0 + 2) && (y_3 == y_2)));
    hard_constraints.push_back(z3::implies(b_4, (y_1 == y_0) && (y_3 == y_1)));
    hard_constraints.push_back(z3::implies(b_7, (z_2 == ctx.bool_val(true))));
    hard_constraints.push_back(z3::implies(b_9, (y_4 == 0) && (y_5 == y_4) && (z_3 == z_2)));
    hard_constraints.push_back(z3::implies(b_11, (y_5 == y_3) && (z_1 == ctx.bool_val(false)) && (z_3 == z_1)));

    // Assumptions
    z3::expr_vector assumptions(ctx);
    assumptions.push_back(z3::implies(b_2, (x_0 >= 32)));
    assumptions.push_back(z3::implies(b_4, !(x_0 >= 32)));
    assumptions.push_back(z3::implies(b_7, (y_3 >= 3)));
    assumptions.push_back(z3::implies(b_11, !(y_3 >= 3)));

    // Instrumentation
    z3::expr_vector instrumentation(ctx);
    z3::expr P = ctx.bool_const("P");
    z3::expr Q = ctx.bool_const("Q");
    instrumentation.push_back(z3::implies(P, (x_0 >= 32) && (!(y_0 >= 2))));
    instrumentation.push_back(z3::implies(Q, (y_5 == (y_0 + 1)) && (z_3 == ctx.bool_val(false))));

    // Solver
    z3::solver solver(ctx);
    solver.add(flow);
    solver.add(hard_constraints);
    solver.add(assumptions);
    solver.add(instrumentation);

    std::cout << solver.assertions() << std::endl;

    // Assumption literals for incremental solving
    z3::expr_vector assumption_literals(ctx);
    // enforce that the predicate P, implying the assumptions of the summary, is always true
    assumption_literals.push_back(P);
    // enforce that the predicate Q, implying the hard constraints of the summary, is always true
    assumption_literals.push_back(Q);
    // enforce that exit location of fb is reachable
    assumption_literals.push_back(b_13);
    // check under assumptions
    z3::check_result check_result = solver.check(assumption_literals);
    switch (check_result) {
        case z3::unsat: {
            std::cout << "UNSAT" << std::endl;
            z3::expr_vector unsat_core = solver.unsat_core();
            std::cout << unsat_core << std::endl;
            break;
        }
        case z3::sat: {
            std::cout << "SAT" << std::endl;
            z3::model model = solver.get_model();
            std::cout << model << std::endl;
            break;
        }
        case z3::unknown:
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }

    ASSERT_EQ(0, 1);
}
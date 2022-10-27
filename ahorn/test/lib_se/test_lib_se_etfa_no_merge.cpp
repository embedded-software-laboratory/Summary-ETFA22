#define SPDLOG_ACTIVE_LEVEL SPDLOG_LEVEL_TRACE

#include <gtest/gtest.h>

#include "cfg/builder.h"
#include "cfg/cfg.h"
#include "compiler/compiler.h"
#include "pass/decision_transformation_pass.h"
#include "se/etfa-no-merge/engine.h"
#include "se/reuse/engine.h"
#include "se/summarization/engine.h"
#include "se/configuration.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/sinks/basic_file_sink.h"
#include "spdlog/sinks/stdout_color_sinks.h"
#include "spdlog/spdlog.h"

#include <fstream>

class TestLibSeETFANoMerge : public ::testing::Test {
public:
    TestLibSeETFANoMerge() : ::testing::Test() {}

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

TEST_F(TestLibSeETFANoMerge, 01) {
    using namespace se::etfa_no_merge;
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

    /*
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
    */

    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFANoMerge, 02) {
    using namespace se::etfa_no_merge;
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

TEST_F(TestLibSeETFANoMerge, Call_Coverage_In_3_Cycles) {
    using namespace se::etfa_no_merge;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/lib_se/file/call_coverage_in_3_cycles.st");
    std::cout << cfg->toDot() << std::endl;
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_no_merge = true;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFANoMerge, Call_Coverage_In_3_Cycles_Unchanged) {
    using namespace se::etfa_no_merge;
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

TEST_F(TestLibSeETFANoMerge, Call_Coverage_In_2_Cycles) {
    using namespace se::etfa_no_merge;
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

TEST_F(TestLibSeETFANoMerge, SF_Antivalent) {
    using namespace se::etfa_no_merge;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/benchmark/dissertation/PLCopen_safety/SFAntivalent.st");
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_no_merge = true;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFANoMerge, SF_Antivalent_ETFA) {
    using namespace se::etfa_no_merge;
    std::shared_ptr<Cfg> cfg = getCfg("../../test/benchmark/etfa/PLCopen_safety/SFAntivalent.st");
    auto configuration = std::make_unique<se::Configuration>();
    configuration->_no_merge = true;
    auto engine = std::make_unique<Engine>(std::move(configuration));
    std::unique_ptr<se::summarization::Engine> summarization_engine =
            std::make_unique<se::summarization::Engine>(engine->getSolver());
    // Phase 1
    summarization_engine->run(*cfg);
    // Phase 2
    engine->run(summarization_engine->getSummarizer(), *cfg);
    ASSERT_EQ(0, 1);
}

TEST_F(TestLibSeETFANoMerge, Test) {
    using namespace se::etfa_no_merge;
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

TEST_F(TestLibSeETFANoMerge, EmergencyStopTest) {
    using namespace se::etfa_no_merge;
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
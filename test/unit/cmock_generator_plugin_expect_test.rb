require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator_plugin_expect"

class CMockGeneratorPluginExpectTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.expect.tab.returns("  ")
    @config.expect.when_ptr_star.returns(:compare_data)
    @config.expect.enforce_strict_ordering.returns(false)
    @config.stubs!(:respond_to?).returns(true)
    @utils.expect.helpers.returns({})
    @cmock_generator_plugin_expect = CMockGeneratorPluginExpect.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_expect.config)
    assert_equal(@utils,  @cmock_generator_plugin_expect.utils)
    assert_equal("  ",    @cmock_generator_plugin_expect.tab)
    assert_equal(nil,     @cmock_generator_plugin_expect.unity_helper)
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_expect.respond_to?(:include_files))
  end
  
  should "add to control structure mock needs of functions of style 'void func(void)'" do
    function = {:name => "Oak", :args => [], :rettype => "void"}
    count_type = "uint32"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(void)'" do
    function = {:name => "Elm", :args => [], :rettype => "int"}
    count_type = "int16"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return_Head;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return_Tail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'void func(int chicken, char* pork)'" do
    function = {:name => "Cedar", :args => [{ :name => "chicken", :type => "int"}, { :name => "pork", :type => "char*"}], :rettype => "void"}
    count_type = "unsigned char"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  int *#{function[:name]}_Expected_chicken;\n",
                "  int *#{function[:name]}_Expected_chicken_Head;\n",
                "  int *#{function[:name]}_Expected_chicken_Tail;\n",
                "  char* *#{function[:name]}_Expected_pork;\n",
                "  char* *#{function[:name]}_Expected_pork_Head;\n",
                "  char* *#{function[:name]}_Expected_pork_Tail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(float beef)'" do
    function = {:name => "Birch", :args => [{ :name => "beef", :type => "float"}], :rettype => "int"}
    count_type = "unsigned int"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return_Head;\n",
                "  #{function[:rettype]} *#{function[:name]}_Return_Tail;\n",
                "  float *#{function[:name]}_Expected_beef;\n",
                "  float *#{function[:name]}_Expected_beef_Head;\n",
                "  float *#{function[:name]}_Expected_beef_Tail;\n",
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'void func(void)'" do
    function = {:name => "Maple", :args_string => "void", :rettype => "void"}
    expected = "void #{function[:name]}_Expect(#{function[:args_string]});\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'int func(void)'" do
    function = {:name => "Spruce", :args_string => "void", :rettype => "int"}
    
    expected = "void #{function[:name]}_ExpectAndReturn(#{function[:rettype]} toReturn);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'const char* func(int tofu)'" do
    function = {:name => "Pine", :args_string => "int tofu", :rettype => "const char*"}
    
    expected = "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:rettype]} toReturn);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
    
  should "not require anything for implementation prefix" do
    assert(!@cmock_generator_plugin_expect.respond_to?(:mock_implementation_prefix))
  end
  
  should "add mock function implementation for functions of style 'void func(void)'" do
    function = {:name => "Apple", :args => [], :rettype => "void"}
    expected = ["  Mock.Apple_CallCount++;\n",
                "  if (Mock.Apple_CallCount > Mock.Apple_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Apple Called More Times Than Expected\");\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function implementation for functions of style 'int func(int veal, unsigned int sushi)'" do
    function = {:name => "Cherry", :args => [ { :type => "int", :name => "veal" }, { :type => "unsigned int", :name => "sushi" } ], :rettype => "int"}
    
    @utils.expect.code_verify_an_arg_expectation(function, function[:args][0][:type], function[:args][0][:name]).returns("mocked_retval_1")
    @utils.expect.code_verify_an_arg_expectation(function, function[:args][1][:type], function[:args][1][:name]).returns("mocked_retval_2")
    
    expected = ["  Mock.Cherry_CallCount++;\n",
                "  if (Mock.Cherry_CallCount > Mock.Cherry_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Cherry Called More Times Than Expected\");\n",
                "  }\n",
                "mocked_retval_1",
                "mocked_retval_2"
               ]
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function implementation using ordering if needed" do
    @utils.expect.expect_helper('int','*p_expected','GlobalVerifyOrder',"\"Function 'Apple' Called Out Of Order.\"", '    ').returns("    mocked_retval")
    function = {:name => "Apple", :args => [], :rettype => "void"}
    expected = ["  Mock.Apple_CallCount++;\n",
                "  if (Mock.Apple_CallCount > Mock.Apple_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Apple Called More Times Than Expected\");\n",
                "  }\n",
                "  {\n",
                "    int* p_expected = Mock.Apple_CallOrder;\n",
                "    ++GlobalVerifyOrder;\n",
                "    if (Mock.Apple_CallOrder != Mock.Apple_CallOrder_Tail)\n",
                "      Mock.Apple_CallOrder++;\n",
                "    mocked_retval",
                "  }\n"
               ]
    @cmock_generator_plugin_expect.ordered = true
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'void func(void)'" do
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    function = {:name => "Pear", :args => [], :args_string => "void", :rettype => "void"}
    expected = ["void Pear_Expect(void)\n",
                "{\n",
                "mock_retval_0",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'unsigned short func(void)'" do
    function = {:name => "Orange", :args => [], :args_string => "void", :rettype => "unsigned short"}
    @utils.expect.code_add_base_expectation("Orange").returns("mock_retval_0")
    @utils.expect.code_insert_item_into_expect_array(function[:rettype], "Mock.Orange_Return_Head","toReturn").returns("mock_retval_1")
    
    expected = ["void Orange_ExpectAndReturn(unsigned short toReturn)\n",
                "{\n",
                "mock_retval_0",
                "mock_retval_1",
                "  Mock.Orange_Return = Mock.Orange_Return_Head;\n",
                "  Mock.Orange_Return += Mock.Orange_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'int func(char* pescado)'" do
    function = {:name => "Lemon", :args => [{ :type => "char*", :name => "pescado"}], :args_string => "char* pescado", :rettype => "int"}
    @utils.expect.code_add_an_arg_expectation(function, "char*", "pescado").returns("mock_retval_2")
    @utils.expect.code_add_base_expectation("Lemon").returns("mock_retval_0")
    @utils.expect.create_call_list(function).returns("mock_retval_3")
    @utils.expect.code_insert_item_into_expect_array(function[:rettype], "Mock.Lemon_Return_Head","toReturn").returns("mock_retval_1")
    
    expected = ["void ExpectParameters_Lemon(char* pescado)\n",
                "{\n",
                "mock_retval_2",
                "}\n\n",
                "void Lemon_ExpectAndReturn(char* pescado, int toReturn)\n",
                "{\n",
                "mock_retval_0",
                "  ExpectParameters_Lemon(mock_retval_3);\n",
                "mock_retval_1",
                "  Mock.Lemon_Return = Mock.Lemon_Return_Head;\n",
                "  Mock.Lemon_Return += Mock.Lemon_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions when using ordering" do
    function = {:name => "Pear", :args => [], :args_string => "void", :rettype => "void"}
    expected = ["void Pear_Expect(void)\n",
                "{\n",
                "mock_retval_0",
                "}\n\n"
               ]
    @cmock_generator_plugin_expect.ordered = true
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock verify lines" do
    function = {:name => "Banana" }
  
    expected = "  TEST_ASSERT_EQUAL_MESSAGE(Mock.Banana_CallsExpected, Mock.Banana_CallCount, \"Function 'Banana' called unexpected number of times.\");\n"
    returned = @cmock_generator_plugin_expect.mock_verify(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'void func(void)'" do
    function = {:name => "Peach", :args => [], :rettype => "void" }
    expected = []
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'char func(void)'" do
    function = {:name => "Palm", :args => [], :rettype => "char" }
    expected = ["  if (Mock.Palm_Return_Head)\n",
                "  {\n",
                "    free(Mock.Palm_Return_Head);\n",
                "    Mock.Palm_Return_Head=NULL;\n",
                "    Mock.Palm_Return_Tail=NULL;\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'int func(uint32 grease)'" do
    function = {:name => "Coconut", :args => [{ :type => "uint32", :name => "grease"}], :rettype => "int" }
    expected = ["  if (Mock.Coconut_Return_Head)\n",
                "  {\n",
                "    free(Mock.Coconut_Return_Head);\n",
                "    Mock.Coconut_Return_Head=NULL;\n",
                "    Mock.Coconut_Return_Tail=NULL;\n",
                "  }\n",
                "  if (Mock.Coconut_Expected_grease_Head)\n",
                "  {\n",
                "    free(Mock.Coconut_Expected_grease_Head);\n",
                "    Mock.Coconut_Expected_grease_Head=NULL;\n",
                "    Mock.Coconut_Expected_grease_Tail=NULL;\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
end

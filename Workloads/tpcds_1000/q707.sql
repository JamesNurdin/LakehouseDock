select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 6 and 6+10 
             or ss_coupon_amt between 3500 and 3500+1000
             or ss_wholesale_cost between 70 and 70+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 165 and 165+10
          or ss_coupon_amt between 3975 and 3975+1000
          or ss_wholesale_cost between 20 and 20+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 58 and 58+10
          or ss_coupon_amt between 13160 and 13160+1000
          or ss_wholesale_cost between 10 and 10+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 188 and 188+10
          or ss_coupon_amt between 6838 and 6838+1000
          or ss_wholesale_cost between 47 and 47+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 36 and 36+10
          or ss_coupon_amt between 6005 and 6005+1000
          or ss_wholesale_cost between 64 and 64+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 187 and 187+10
          or ss_coupon_amt between 15823 and 15823+1000
          or ss_wholesale_cost between 51 and 51+20)) B6
limit 100;

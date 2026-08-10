select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 181 and 181+10 
             or ss_coupon_amt between 12564 and 12564+1000
             or ss_wholesale_cost between 77 and 77+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 33 and 33+10
          or ss_coupon_amt between 12174 and 12174+1000
          or ss_wholesale_cost between 7 and 7+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 35 and 35+10
          or ss_coupon_amt between 16246 and 16246+1000
          or ss_wholesale_cost between 58 and 58+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 74 and 74+10
          or ss_coupon_amt between 7736 and 7736+1000
          or ss_wholesale_cost between 30 and 30+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 130 and 130+10
          or ss_coupon_amt between 17459 and 17459+1000
          or ss_wholesale_cost between 21 and 21+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 137 and 137+10
          or ss_coupon_amt between 6442 and 6442+1000
          or ss_wholesale_cost between 20 and 20+20)) B6
limit 100;

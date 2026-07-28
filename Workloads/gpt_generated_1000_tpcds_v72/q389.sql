WITH sales_agg AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit)       AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT i.i_manufact_id,
       cp.cp_department,
       c_bill.c_customer_id   AS bill_customer_id,
       c_ship.c_customer_id   AS ship_customer_id,
       SUM(sa.total_sales)    AS agg_sales,
       SUM(sa.total_profit)   AS agg_profit,
       COALESCE(SUM(cr.cr_return_amount), 0)   AS total_catalog_return,
       COALESCE(SUM(sr.sr_return_amt), 0)      AS total_store_return,
       COALESCE(SUM(wr.wr_return_amt), 0)      AS total_web_return,
       COUNT(DISTINCT cr.cr_order_number)      AS catalog_return_cnt,
       (
           SELECT COUNT(*)
           FROM catalog_returns cr2
           WHERE cr2.cr_item_sk = i.i_item_sk
             AND cr2.cr_return_amount > 100
       )                                          AS high_value_return_cnt
FROM sales_agg sa
JOIN catalog_sales cs               ON sa.cs_item_sk = cs.cs_item_sk
JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
JOIN customer c_bill                ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship                ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN catalog_page cp_ret        ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN item i_ret                ON cr.cr_item_sk = i_ret.i_item_sk
LEFT JOIN customer c_refund         ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN customer c_sr             ON sr.sr_customer_sk = c_sr.c_customer_sk
LEFT JOIN household_demographics hd_sr   ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN customer c_wr_refund       ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
LEFT JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
GROUP BY i.i_manufact_id,
         cp.cp_department,
         c_bill.c_customer_id,
         c_ship.c_customer_id,
         i.i_item_sk,
         cr.cr_order_number,
         hd_bill.hd_demo_sk,
         hd_ship.hd_demo_sk,
         hd_refund.hd_demo_sk,
         hd_sr.hd_demo_sk,
         hd_wr_refund.hd_demo_sk,
         cp_ret.cp_catalog_page_sk,
         i_ret.i_item_sk,
         c_refund.c_customer_sk,
         c_sr.c_customer_sk,
         c_wr_refund.c_customer_sk
ORDER BY agg_sales DESC
LIMIT 100

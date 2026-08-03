WITH
ss_raw AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_item_sk,
       ss.ss_sold_time_sk,
       ss.ss_net_paid,
       ss.ss_net_profit,
       ss.ss_customer_sk,
       td.t_hour,
       i.i_color,
       i.i_brand,
       cd.cd_credit_rating,
       ca.ca_state,
       p.p_promo_id
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
cs_raw AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_time_sk,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_quantity,
       td.t_hour,
       i.i_color,
       i.i_brand,
       cd.cd_credit_rating,
       ca.ca_state,
       p.p_promo_id,
       cc.cc_name,
       cp.cp_catalog_page_number,
       sm.sm_carrier,
       w.w_gmt_offset
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
),
wr_raw AS (
   SELECT
       wr.wr_item_sk,
       wr.wr_returned_time_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       td.t_hour,
       i.i_color,
       i.i_brand,
       cd.cd_credit_rating,
       ca.ca_state,
       p.p_promo_id
   FROM web_returns wr
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk
),
intersect_items AS (
   SELECT ss_item_sk AS item_sk FROM ss_raw
   INTERSECT
   SELECT cs_item_sk FROM cs_raw
),
sales_agg AS (
   SELECT
       ca_state AS state,
       SUM(ss_net_paid) AS total_net_paid_sales,
       SUM(ss_net_profit) AS total_profit_sales,
       COUNT(*) AS sales_cnt
   FROM ss_raw
   WHERE cd_credit_rating = 'Good'
     AND i_color = 'RED'
     AND i_brand = 'Brand#12'
     AND t_hour BETWEEN 9 AND 17
     AND ss_ticket_number NOT IN (
         SELECT sr_ticket_number FROM store_returns WHERE sr_return_quantity > 0
     )
   GROUP BY ca_state
),
catalog_agg AS (
   SELECT
       ca_state AS state,
       SUM(cs_net_paid) AS total_net_paid_catalog,
       SUM(cs_net_profit) AS total_profit_catalog,
       COUNT(*) AS catalog_cnt
   FROM cs_raw
   WHERE cd_credit_rating = 'Good'
     AND i_color = 'RED'
     AND i_brand = 'Brand#12'
     AND sm_carrier = 'DHL'
     AND w_gmt_offset = -5.00
     AND t_hour BETWEEN 9 AND 17
     AND cs_item_sk IN (SELECT item_sk FROM intersect_items)
   GROUP BY ca_state
),
combined_agg AS (
   SELECT
       ca_state AS state,
       SUM(wr_return_amt) AS total_return_amount,
       COUNT(*) AS return_cnt
   FROM wr_raw
   WHERE cd_credit_rating = 'Good'
     AND i_color = 'RED'
     AND i_brand = 'Brand#12'
     AND t_hour BETWEEN 9 AND 17
   GROUP BY ca_state
),
final_join AS (
   SELECT
       COALESCE(s.state, c.state, r.state) AS state,
       s.total_net_paid_sales,
       s.total_profit_sales,
       c.total_net_paid_catalog,
       c.total_profit_catalog,
       r.total_return_amount,
       (COALESCE(s.total_net_paid_sales,0) + COALESCE(c.total_net_paid_catalog,0)) AS total_net_paid_combined,
       (COALESCE(s.total_profit_sales,0) + COALESCE(c.total_profit_catalog,0)) AS total_profit_combined
   FROM sales_agg s
   FULL OUTER JOIN catalog_agg c ON s.state = c.state
   FULL OUTER JOIN combined_agg r ON COALESCE(s.state, c.state) = r.state
)
SELECT
    state,
    total_net_paid_sales,
    total_profit_sales,
    total_net_paid_catalog,
    total_profit_catalog,
    total_return_amount,
    total_net_paid_combined,
    total_profit_combined
FROM final_join
WHERE total_net_paid_combined > 10000
ORDER BY total_net_paid_combined DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

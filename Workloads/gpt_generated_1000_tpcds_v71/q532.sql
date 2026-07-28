WITH ss AS (
        SELECT
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_store_sk,
            ss_ticket_number,
            ss_item_sk,
            ss_addr_sk,
            ss_net_paid,
            ss_list_price
        FROM store_sales
        WHERE ss_list_price > 100
    ),
    sr AS (
        SELECT
            sr_store_sk,
            sr_return_time_sk,
            sr_ticket_number,
            sr_item_sk,
            sr_addr_sk,
            sr_net_loss
        FROM store_returns
        WHERE sr_net_loss > 0
    ),
    cs AS (
        SELECT
            cs_call_center_sk,
            cs_sold_time_sk,
            cs_ext_ship_cost,
            cs_sales_price,
            cs_net_paid_inc_ship_tax,
            cs_bill_addr_sk
        FROM catalog_sales
        WHERE cs_ext_ship_cost > 500
    ),
    wr AS (
        SELECT
            wr_returned_time_sk,
            wr_return_amt,
            wr_refunded_addr_sk
        FROM web_returns
        WHERE wr_return_amt > 200
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    td.t_hour,
    COUNT(DISTINCT ss.ss_ticket_number)                     AS orders_count,
    SUM(ss.ss_net_paid)                                    AS total_store_sales,
    SUM(sr.sr_net_loss)                                    AS total_store_returns_loss,
    SUM(cs.cs_net_paid_inc_ship_tax)                       AS total_catalog_sales,
    AVG(cs.cs_sales_price)                                 AS avg_catalog_price,
    COUNT(wr.wr_returned_time_sk)                          AS web_returns_cnt
FROM ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN sr
  ON sr.sr_store_sk = s.s_store_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_return_time_sk = td.t_time_sk
JOIN cs
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN wr
  ON wr.wr_returned_time_sk = td.t_time_sk
WHERE ca_ss.ca_state = 'CA'
  AND s.s_city = 'Seattle'
  AND td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returned_time_sk = td.t_time_sk
          AND wr2.wr_return_amt > 300
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    td.t_hour
ORDER BY total_store_sales DESC
LIMIT 100

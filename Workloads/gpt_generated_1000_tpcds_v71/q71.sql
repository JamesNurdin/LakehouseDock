WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_category,
        i.i_product_name,
        td.t_hour,
        cd.cd_gender,
        ca.ca_state,
        s.s_store_name,
        s.s_manager,
        s.s_market_desc
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
      AND cd.cd_gender = 'F'
      AND ca.ca_state = 'CA'
      AND s.s_market_desc = 'Urban'
      AND s.s_manager = 'Wayne Coleman'
)
SELECT
    bs.s_store_name,
    bs.s_manager,
    bs.i_category,
    bs.i_product_name,
    bs.t_hour,
    COUNT(DISTINCT bs.ss_ticket_number) AS num_transactions,
    SUM(bs.ss_quantity) AS total_units_sold,
    SUM(bs.ss_net_paid) AS total_sales_amount,
    SUM(bs.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = bs.ss_store_sk
    ) AS avg_store_profit
FROM base_sales bs
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = bs.ss_ticket_number
   AND sr.sr_item_sk = bs.ss_item_sk
   AND sr.sr_store_sk = bs.ss_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = bs.ss_item_sk
   AND wr.wr_returned_time_sk = bs.ss_sold_time_sk
GROUP BY
    bs.s_store_name,
    bs.s_manager,
    bs.i_category,
    bs.i_product_name,
    bs.t_hour,
    bs.ss_store_sk
ORDER BY total_sales_amount DESC
LIMIT 100

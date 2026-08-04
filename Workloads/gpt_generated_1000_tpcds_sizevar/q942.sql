WITH common_items AS (
    SELECT sr_item_sk
    FROM store_returns
    INTERSECT
    SELECT wr_item_sk
    FROM web_returns
),
sr_base AS (
    SELECT 
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_return_time_sk,
        sr.sr_addr_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        i.i_brand,
        i.i_category,
        s.s_store_name,
        ca.ca_city,
        hd.hd_vehicle_count,
        t.t_hour
    FROM store_returns sr
    JOIN common_items ci ON sr.sr_item_sk = ci.sr_item_sk
    FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
),
wr_base AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        i2.i_brand AS wr_brand,
        i2.i_category AS wr_category,
        ca2.ca_city AS refunded_city,
        ca3.ca_city AS returning_city,
        hd2.hd_vehicle_count AS refunded_vehicle_count,
        hd3.hd_vehicle_count AS returning_vehicle_count,
        t2.t_hour AS return_hour
    FROM web_returns wr
    JOIN common_items ci ON wr.wr_item_sk = ci.sr_item_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    JOIN customer_address ca3 ON wr.wr_returning_addr_sk = ca3.ca_address_sk
    JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN household_demographics hd3 ON wr.wr_returning_hdemo_sk = hd3.hd_demo_sk
    JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
)
SELECT
    COALESCE(sr.sr_ticket_number, wr.wr_order_number) AS transaction_id,
    CASE
        WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    SUM(COALESCE(sr.sr_return_amt_inc_tax, 0) + COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    COUNT(*) AS txn_count,
    lb.dist_brand_cnt
FROM sr_base sr
FULL OUTER JOIN wr_base wr
    ON sr.sr_item_sk = wr.wr_item_sk
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT b.i_brand) AS dist_brand_cnt
    FROM item b
    WHERE b.i_item_sk = COALESCE(sr.sr_item_sk, wr.wr_item_sk)
) lb
GROUP BY
    COALESCE(sr.sr_ticket_number, wr.wr_order_number),
    CASE
        WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 1000 THEN 'High'
        ELSE 'Low'
    END,
    lb.dist_brand_cnt
ORDER BY total_net_loss DESC
OFFSET 10
LIMIT 100

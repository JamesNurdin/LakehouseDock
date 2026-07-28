WITH
    sr AS (
        SELECT
            sr_returned_date_sk,
            sr_return_time_sk,
            sr_item_sk,
            sr_store_sk,
            sr_reason_sk,
            sr_addr_sk,
            sr_net_loss
        FROM store_returns
    ),
    cr AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_item_sk,
            cr_call_center_sk,
            cr_reason_sk,
            cr_return_amount
        FROM catalog_returns
        WHERE cr_return_amount > 1000
    ),
    ws AS (
        SELECT
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_item_sk,
            ws_net_paid,
            ws_net_profit
        FROM web_sales
        WHERE ws_net_profit > 0
    )
SELECT
    d.d_date,
    s.s_store_name,
    s.s_market_desc,
    i.i_product_name,
    cc.cc_name,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    CASE
        WHEN SUM(sr.sr_net_loss) > (SELECT AVG(sr_net_loss) FROM store_returns) THEN 'Above Avg Loss'
        ELSE 'Below Avg Loss'
    END AS loss_category,
    RANK() OVER (PARTITION BY s.s_market_id ORDER BY SUM(sr.sr_net_loss) DESC) AS market_loss_rank
FROM date_dim d
JOIN sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
JOIN item i ON i.i_item_sk = sr.sr_item_sk
JOIN time_dim t ON t.t_time_sk = sr.sr_return_time_sk
JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
JOIN cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN ws ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND s.s_market_id IN (4, 6)
  AND i.i_brand = 'Brand#23'
  AND cc.cc_state = 'CA'
GROUP BY
    d.d_date,
    s.s_store_name,
    s.s_market_desc,
    i.i_product_name,
    cc.cc_name,
    r.r_reason_desc,
    s.s_market_id
ORDER BY total_store_net_loss DESC
LIMIT 100

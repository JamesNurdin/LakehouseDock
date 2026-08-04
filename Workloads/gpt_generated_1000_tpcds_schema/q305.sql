WITH web_orders AS (
    SELECT
        wr.wr_order_number,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS reason_first_word
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '^Did not')
),
catalog_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
),
unique_order_numbers AS (
    SELECT wr_order_number
    FROM web_orders
    EXCEPT
    SELECT cr_order_number
    FROM catalog_orders
),
joined_data AS (
    SELECT
        uon.wr_order_number,
        wo.wr_net_loss,
        c.c_customer_id,
        hd.hd_buy_potential,
        sm.sm_carrier,
        wo.reason_first_word,
        CONCAT('Cust-', c.c_customer_id) AS cust_label,
        SUBSTRING(c.c_customer_id, 1, 3) AS cust_prefix
    FROM unique_order_numbers uon
    JOIN web_orders wo ON uon.wr_order_number = wo.wr_order_number
    JOIN customer c ON wo.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON uon.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier LIKE 'U%'
      AND lower(wo.reason_first_word) LIKE '%did%'
)
SELECT
    cust_label,
    cust_prefix,
    hd_buy_potential,
    sm_carrier,
    SUM(wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr_net_loss) > 1000 THEN 'High Loss'
        WHEN SUM(wr_net_loss) > 500 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM joined_data
GROUP BY cust_label, cust_prefix, hd_buy_potential, sm_carrier
ORDER BY total_net_loss DESC
LIMIT 100

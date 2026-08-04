WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        r.r_reason_desc,
        p.p_promo_name,
        t.t_hour,
        c_ref.c_customer_id   AS refunded_customer_id,
        c_ret.c_customer_id   AS returning_customer_id,
        ca_ref.ca_state       AS refunded_state,
        ca_ret.ca_state       AS returning_state,
        ws.ws_quantity,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN web_sales ws ON cr.cr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ca_ret.ca_state IN ('CA', 'NY', 'TX')
      AND p.p_channel_email = 'N'
      AND r.r_reason_desc LIKE '%defect%'
      AND cr.cr_return_amount > 10
      AND ws.ws_quantity > 0
),
agg1 AS (
    SELECT
        profit_flag,
        SUM(cr_return_amount)        AS total_return_amount,
        SUM(ws_ext_sales_price)      AS total_sales_price,
        COUNT(DISTINCT cr_order_number) AS order_cnt
    FROM base
    GROUP BY profit_flag
    HAVING SUM(cr_return_amount) > 1000
),
agg2 AS (
    SELECT
        CAST(t.t_hour AS varchar) AS hour_label,
        SUM(cr.cr_return_amount) AS hour_return_sum,
        COUNT(*)               AS cnt,
        t.t_hour               AS hour_value
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_amount > 5
    GROUP BY t.t_hour
),
set_diff AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 20
),
set_common AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 1
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
),
union_all AS (
    SELECT
        profit_flag            AS category,
        total_return_amount    AS amount,
        total_sales_price      AS sales,
        order_cnt              AS cnt,
        NULL                   AS hour
    FROM agg1
    UNION
    SELECT
        hour_label            AS category,
        hour_return_sum       AS amount,
        NULL                  AS sales,
        cnt                   AS cnt,
        hour_value            AS hour
    FROM agg2
)
SELECT
    u.category,
    u.amount,
    u.sales,
    u.cnt,
    u.hour
FROM union_all u
WHERE u.category IN (SELECT CAST(cr_order_number AS varchar) FROM set_diff)
  AND u.category NOT IN (SELECT CAST(cr_order_number AS varchar) FROM set_common)
ORDER BY u.amount DESC
OFFSET 10
LIMIT 100

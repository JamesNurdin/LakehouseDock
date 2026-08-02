WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS qty_price_arr
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
),
sales_unnested AS (
    SELECT
        sb.*,
        u.val AS metric_value,
        CASE WHEN u.ordinal = 1 THEN 'quantity' ELSE 'ext_sales_price' END AS metric_type
    FROM sales_base sb
    CROSS JOIN UNNEST(sb.qty_price_arr) WITH ORDINALITY AS u(val, ordinal)
),
enriched AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        c.c_customer_id,
        d_sold.d_year,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        r.r_reason_desc,
        wp.wp_type,
        ws.web_name,
        su.metric_type,
        su.metric_value,
        SUM(su.metric_value) OVER (
            PARTITION BY cc.cc_state
            ORDER BY su.metric_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_metric,
        ROW_NUMBER() OVER (
            PARTITION BY cc.cc_state
            ORDER BY su.metric_value DESC
        ) AS rn
    FROM sales_unnested su
    JOIN date_dim d_sold ON su.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON su.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON su.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON su.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON su.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws ON ws.web_close_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_vehicle_count >= 0
      AND cc.cc_state = 'CA'
      AND d_sold.d_holiday = 'N'
)
SELECT *
FROM enriched
WHERE rn <= 10
LIMIT 100

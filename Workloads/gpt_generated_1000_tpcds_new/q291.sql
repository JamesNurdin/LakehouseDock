WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk
    FROM catalog_sales cs
)
SELECT
    bs.cs_order_number,
    bs.cs_sales_price,
    SUM(cr.cr_return_amount)                                    AS total_return_amount,
    SUM(ss.sr_net_loss)                                         AS total_store_net_loss,
    SUM(wr.wr_net_loss)                                         AS total_web_net_loss,
    sm.sm_code,
    token.code_token,
    CASE WHEN bs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END   AS profit_flag,
    ROW_NUMBER() OVER (ORDER BY bs.cs_order_number)            AS row_num
FROM base_sales bs
FULL OUTER JOIN catalog_returns cr
    ON bs.cs_order_number = cr.cr_order_number
JOIN customer cust
    ON bs.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer_demographics cdemo
    ON bs.cs_bill_cdemo_sk = cdemo.cd_demo_sk
JOIN call_center cc
    ON bs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON bs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion promo
    ON bs.cs_promo_sk = promo.p_promo_sk
JOIN ship_mode sm
    ON bs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON bs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN store_returns ss
    ON ss.sr_customer_sk = cust.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cust.c_customer_sk
CROSS JOIN UNNEST(split(sm.sm_code, '\\s+')) AS token (code_token)
WHERE
    bs.cs_sold_date_sk BETWEEN 2450830 AND 2450839
    AND bs.cs_quantity > 1
    AND bs.cs_sales_price > 100
    AND cc.cc_country = 'USA'
    AND promo.p_discount_active = 'Y'
GROUP BY
    bs.cs_order_number,
    bs.cs_sales_price,
    sm.sm_code,
    token.code_token,
    bs.cs_net_profit
ORDER BY
    bs.cs_order_number DESC
LIMIT 100

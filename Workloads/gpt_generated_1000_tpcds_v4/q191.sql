WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451174
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_promo_sk
)
SELECT
    DISTINCT s.s_store_name,
    d_sales.d_year,
    p.p_promo_name,
    CASE WHEN sa.total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    sa.total_net_profit,
    sa.total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = sa.ss_sold_date_sk
   AND cs.cs_promo_sk = sa.ss_promo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
   AND wr.wr_reason_sk = (
        SELECT r.r_reason_sk
        FROM reason r
        WHERE r.r_reason_desc = 'Wrong size'
        LIMIT 1
    )
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    d_sales.d_year = 2001
    AND s.s_state = 'CA'
    AND cc.cc_state = 'CA'
    AND p.p_channel_email = 'N'
    AND cp.cp_catalog_number IN (5, 13, 15)
    AND t.t_hour BETWEEN 9 AND 17
    AND r.r_reason_desc = 'Wrong size'
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
          AND cs2.cs_quantity > 5
    )
GROUP BY
    s.s_store_name,
    d_sales.d_year,
    p.p_promo_name,
    CASE WHEN sa.total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END,
    sa.total_net_profit,
    sa.total_quantity
ORDER BY sa.total_net_profit DESC
LIMIT 100

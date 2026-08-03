WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2451910 AND 2451950
),
agg AS (
    SELECT
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        ch.channel,
        SUM(ss.cs_ext_sales_price) AS total_sales,
        AVG(ss.cs_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT ss.cs_order_number) AS orders_cnt,
        MIN(ss.cs_list_price) AS min_list_price,
        MAX(ss.cs_net_profit) AS max_net_profit
    FROM sampled_sales ss
    JOIN call_center cc
        ON ss.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON ss.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill
        ON ss.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON ss.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ss.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship
        ON ss.cs_ship_addr_sk = ca_ship.ca_address_sk
    CROSS JOIN UNNEST(ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_radio]) AS ch(channel)
    WHERE
        cc.cc_tax_percentage > 0.05
        AND cp.cp_department = 'Electronics'
        AND cd_bill.cd_credit_rating = 'High Risk'
        AND p.p_discount_active = 'Y'
    GROUP BY
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        ch.channel
)
SELECT
    cc_name,
    cp_department,
    p_promo_name,
    total_sales,
    avg_wholesale_cost,
    orders_cnt,
    min_list_price,
    max_net_profit,
    LAG(total_sales) OVER (PARTITION BY cc_name ORDER BY cp_department) AS lag_total_sales,
    SUM(total_sales) OVER (PARTITION BY cc_name ORDER BY cp_department ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    channel
FROM agg
ORDER BY total_sales DESC
LIMIT 100

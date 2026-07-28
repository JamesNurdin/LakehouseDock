WITH sales_agg AS (
    SELECT
        cc.cc_market_manager AS market_manager,
        cc.cc_state AS state,
        cd.cd_gender AS gender,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_market_manager IN ('Daniel Weller', 'Julius Tran')
      AND cc.cc_state = 'CA'
      AND cs.cs_list_price > 50.00
      AND cs.cs_sales_price BETWEEN 10.00 AND 200.00
      AND p.p_channel_press = 'N'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
      AND cs.cs_ship_addr_sk IN (4818292, 5947632)
    GROUP BY ROLLUP (cc.cc_market_manager, cc.cc_state, cd.cd_gender, p.p_promo_name)
)
SELECT
    market_manager,
    state,
    gender,
    promo_name,
    total_sales,
    total_quantity,
    avg_sales_price,
    SUM(total_sales) OVER (PARTITION BY market_manager ORDER BY state ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_manager,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY market_manager, state, gender, promo_name
LIMIT 100

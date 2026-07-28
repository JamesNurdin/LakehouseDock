WITH base AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        i.inv_quantity_on_hand,
        i.inv_warehouse_sk,
        w.web_name,
        w.web_state,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        RANK() OVER (PARTITION BY d.d_year, cd.cd_gender ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE cs.cs_ext_tax > 100.00                      -- predicate 1
      AND cs.cs_coupon_amt < 500.00                  -- predicate 2
      AND cd.cd_gender = 'M'                         -- predicate 3
      AND d.d_year = 1998                            -- predicate 4
      AND i.inv_warehouse_sk IN (2, 12)               -- predicate 5
      AND w.web_state = 'CA'                         -- predicate 6
)
SELECT 
    cs_order_number,
    cs_net_profit,
    d_year,
    d_month_seq,
    cd_gender,
    inv_quantity_on_hand,
    web_name,
    profit_category,
    profit_rank
FROM base
ORDER BY d_year, cd_gender, profit_rank
LIMIT 100

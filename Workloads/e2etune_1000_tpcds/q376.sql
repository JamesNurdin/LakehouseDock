WITH daily_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS cc_sk,
        SUM(cs.cs_net_profit) AS daily_profit,
        SUM(cs.cs_sales_price) AS daily_sales,
        SUM(cs.cs_quantity) AS daily_quantity
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY cs.cs_sold_date_sk, cs.cs_call_center_sk
),

daily_inventory AS (
    SELECT
        inv.inv_date_sk AS date_sk,
        SUM(inv.inv_quantity_on_hand) AS daily_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_date_sk
),

base AS (
    SELECT
        cc.cc_state,
        d.d_year,
        d.d_month_seq,
        SUM(ds.daily_profit) AS total_net_profit,
        SUM(ds.daily_sales) AS total_sales,
        SUM(ds.daily_quantity) AS total_quantity_sold,
        COALESCE(SUM(di.daily_inventory_qty), 0) AS total_inventory_on_hand,
        (SUM(ds.daily_profit) / NULLIF(SUM(ds.daily_sales), 0)) AS profit_to_sales_ratio,
        (SUM(ds.daily_quantity) / NULLIF(SUM(di.daily_inventory_qty), 0)) AS qty_sold_to_inventory_ratio
    FROM daily_sales ds
    JOIN call_center cc ON ds.cc_sk = cc.cc_call_center_sk
    JOIN date_dim d ON ds.date_sk = d.d_date_sk
    LEFT JOIN daily_inventory di ON ds.date_sk = di.date_sk
    WHERE cc.cc_state IN ('TN', 'LA')
      AND d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_employees > 1500000
    GROUP BY cc.cc_state, d.d_year, d.d_month_seq
    HAVING SUM(ds.daily_profit) > 0
)
SELECT
    b.cc_state,
    b.d_year,
    b.d_month_seq,
    b.total_net_profit,
    b.total_sales,
    b.total_quantity_sold,
    b.total_inventory_on_hand,
    b.profit_to_sales_ratio,
    b.qty_sold_to_inventory_ratio,
    ROW_NUMBER() OVER (PARTITION BY b.cc_state ORDER BY b.total_net_profit DESC) AS profit_month_rank
FROM base b
ORDER BY b.total_net_profit DESC
LIMIT 100

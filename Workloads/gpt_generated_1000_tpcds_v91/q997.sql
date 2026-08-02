WITH
store_sales_agg AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        SUM(ss_net_profit) AS net_profit
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_wholesale_cost > 0
      AND ss_list_price > 0
    GROUP BY ss_sold_date_sk, ss_item_sk, ss_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS net_profit
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_ext_ship_cost > 5
      AND cs_ext_list_price > 1000
    GROUP BY cs_sold_date_sk, cs_item_sk, cs_bill_customer_sk
),
union_sales AS (
    -- Store sales branch
    SELECT
        d.d_year,
        i.i_category,
        ss.customer_sk,
        ss.item_sk,
        ss.net_profit
    FROM store_sales_agg ss
    JOIN date_dim d ON ss.date_sk = d.d_date_sk
    JOIN item i ON ss.item_sk = i.i_item_sk
    WHERE d.d_year >= 1999
      AND i.i_brand = 'Brand#12'
      AND i.i_size = 'M'
    UNION DISTINCT
    -- Catalog sales branch with all remaining dimensions
    SELECT
        d.d_year,
        i.i_category,
        cs.customer_sk,
        cs.item_sk,
        cs.net_profit
    FROM catalog_sales_agg cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    JOIN item i ON cs.item_sk = i.i_item_sk
    JOIN catalog_sales cs_raw
        ON cs_raw.cs_sold_date_sk = d.d_date_sk
       AND cs_raw.cs_item_sk = i.i_item_sk
       AND cs_raw.cs_bill_customer_sk = cs.customer_sk
    JOIN call_center cc
        ON cs_raw.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs_raw.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs_raw.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs_raw.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs_raw.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs_raw.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year >= 1999
      AND i.i_brand = 'Brand#12'
      AND t.t_am_pm = 'PM'
      AND cc.cc_class = 'A'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
)
SELECT
    us.d_year,
    us.i_category,
    SUM(us.net_profit) AS total_net_profit,
    COUNT(DISTINCT us.customer_sk) AS distinct_customers,
    COUNT(DISTINCT us.item_sk) AS distinct_items
FROM union_sales us
GROUP BY us.d_year, us.i_category
HAVING SUM(us.net_profit) > (
    SELECT AVG(yearly_profit) FROM (
        SELECT SUM(net_profit) AS yearly_profit
        FROM union_sales
        GROUP BY d_year
    ) avg_year
)
ORDER BY total_net_profit DESC

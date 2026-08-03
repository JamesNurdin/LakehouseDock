WITH sampled_inventory AS (
   SELECT *
   FROM inventory
   TABLESAMPLE BERNOULLI (10)
),

sales_agg AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       cs.cs_promo_sk,
       cs.cs_catalog_page_sk,
       cs.cs_bill_customer_sk,
       cs.cs_bill_addr_sk,
       cs.cs_bill_hdemo_sk,
       cs.cs_bill_cdemo_sk
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 0
),

base AS (
   SELECT
       cp.cp_department      AS cp_department,
       i.i_category,
       i.i_class,
       d.d_year,
       ca.ca_state,
       ws.web_name,
       CASE WHEN sa.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
       (SELECT max(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = sa.cs_promo_sk) AS max_promo_cost,
       sa.cs_ext_sales_price,
       sa.cs_quantity,
       ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY sa.cs_ext_sales_price DESC NULLS LAST) AS dept_rank
   FROM sales_agg sa
   JOIN date_dim d       ON sa.cs_sold_date_sk = d.d_date_sk
   JOIN item i           ON sa.cs_item_sk = i.i_item_sk
   JOIN promotion p      ON sa.cs_promo_sk = p.p_promo_sk
   RIGHT OUTER JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c      ON sa.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sa.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = sa.cs_item_sk
   LEFT JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN store s           ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_page wp       ON wp.wp_customer_sk = c.c_customer_sk
   LEFT JOIN web_site ws       ON ws.web_open_date_sk = d.d_date_sk
   LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = sa.cs_item_sk AND inv.inv_date_sk = sa.cs_sold_date_sk
   LEFT JOIN date_dim d_ret    ON sr.sr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN time_dim t_ret    ON sr.sr_return_time_sk = t_ret.t_time_sk
   WHERE d.d_year = 2002
     AND i.i_class = 'accessories'
     AND ca.ca_state = 'CA'
     AND p.p_channel_catalog = 'N'
     AND cp.cp_department = 'Books'
     AND sa.cs_ext_sales_price > 1000
)
SELECT *
FROM base
WHERE dept_rank <= 5
ORDER BY cp_department, dept_rank
LIMIT 100

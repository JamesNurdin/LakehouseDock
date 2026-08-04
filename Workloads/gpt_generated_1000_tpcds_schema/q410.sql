WITH sales_union AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       ws.ws_ship_mode_sk AS ship_mode_sk,
       ws.ws_net_profit AS net_profit,
       ws.ws_ext_tax AS tax_amount,
       ws.ws_quantity AS quantity,
       ws.ws_web_site_sk AS web_site_sk,
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_bill_cdemo_sk AS cdemo_sk
   FROM web_sales ws
   WHERE ws.ws_ext_tax > (SELECT MAX(sr_return_tax) FROM store_returns)
   UNION DISTINCT
   SELECT
       sr.sr_item_sk AS item_sk,
       CAST(NULL AS integer) AS ship_mode_sk,
       -sr.sr_net_loss AS net_profit,
       sr.sr_return_tax AS tax_amount,
       sr.sr_return_quantity AS quantity,
       CAST(NULL AS integer) AS web_site_sk,
       sr.sr_customer_sk AS customer_sk,
       sr.sr_cdemo_sk AS cdemo_sk
   FROM store_returns sr
   WHERE sr.sr_return_tax < (SELECT MIN(ws_ext_tax) FROM web_sales)
),
agg1 AS (
   SELECT
       i.i_category AS category,
       sm.sm_code AS ship_mode,
       CASE WHEN i.i_color = 'smoke' THEN 'SMOKE' ELSE 'OTHER' END AS color_group,
       SUM(su.net_profit) AS total_profit,
       AVG(su.tax_amount) AS avg_tax,
       COUNT(DISTINCT su.customer_sk) AS distinct_customers
   FROM sales_union su
   JOIN item i TABLESAMPLE BERNOULLI (10) ON su.item_sk = i.i_item_sk
   LEFT JOIN ship_mode sm ON su.ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN customer c ON su.customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd ON su.cdemo_sk = cd.cd_demo_sk
   LEFT JOIN web_site ws ON su.web_site_sk = ws.web_site_sk
   WHERE i.i_current_price BETWEEN 10 AND 100
     AND i.i_units IN ('Pound', 'Bundle')
     AND cd.cd_purchase_estimate >= 2000
     AND cd.cd_marital_status = 'M'
     AND sm.sm_code = 'AIR'
     AND ws.web_country = 'United States'
   GROUP BY i.i_category,
            sm.sm_code,
            CASE WHEN i.i_color = 'smoke' THEN 'SMOKE' ELSE 'OTHER' END
),
final AS (
   SELECT
       category,
       ship_mode,
       color_group,
       total_profit,
       avg_tax,
       distinct_customers,
       total_profit / NULLIF(distinct_customers, 0) AS profit_per_customer
   FROM agg1
   WHERE total_profit > 0
)
SELECT
   category,
   ship_mode,
   color_group,
   total_profit,
   avg_tax,
   distinct_customers,
   profit_per_customer
FROM final
ORDER BY profit_per_customer DESC
LIMIT 100

WITH base AS (
   SELECT
       s.s_store_id,
       s.s_state,
       i.i_category,
       i.i_brand,
       d1.d_year,
       d1.d_weekend,
       d1.d_date,
       ss.ss_net_paid,
       ss.ss_quantity,
       ss.ss_ticket_number,
       ss.ss_sales_price,
       ss.ss_net_profit,
       sr.sr_return_quantity,
       cr.cr_return_quantity,
       cd.cd_marital_status,
       ib.ib_lower_bound,
       cc.cc_market_manager,
       cc.cc_mkt_id,
       -- scalar subquery: average current price for the item category
       (SELECT AVG(i3.i_current_price) FROM item i3 WHERE i3.i_category = i.i_category) AS category_avg_price
   FROM store_sales ss
   JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_store_sk = s.s_store_sk
   JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
       AND cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
   JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
   JOIN date_dim d3 ON sr.sr_returned_date_sk = d3.d_date_sk
   JOIN date_dim d4 ON cr.cr_returned_date_sk = d4.d_date_sk
   WHERE cc.cc_market_manager = 'Matthew Clifton'
     AND cc.cc_mkt_id = 5
     AND cd.cd_marital_status = 'M'
     AND d1.d_weekend = 'N'
     AND i.i_brand = 'BrandX'
     AND s.s_state = 'CA'
     AND ib.ib_lower_bound >= 50000
     AND d1.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
     AND NOT EXISTS (
         SELECT 1 FROM catalog_returns cr2
         WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
     )
)
SELECT
    store_id,
    state,
    category,
    year,
    SUM(net_paid) AS total_net_paid,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT ticket_number) AS distinct_tickets,
    SUM(store_return_qty) AS total_store_returns,
    SUM(catalog_return_qty) AS total_catalog_returns,
    AVG(sales_price) AS avg_sales_price,
    CASE WHEN SUM(net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    category_avg_price,
    RANK() OVER (PARTITION BY state ORDER BY SUM(net_paid) DESC) AS state_rank,
    SUM(SUM(net_paid)) OVER (PARTITION BY state) AS state_total_net_paid
FROM (
    SELECT
        s_store_id AS store_id,
        s_state AS state,
        i_category AS category,
        d_year AS year,
        ss_net_paid AS net_paid,
        ss_quantity AS quantity,
        ss_ticket_number AS ticket_number,
        sr_return_quantity AS store_return_qty,
        cr_return_quantity AS catalog_return_qty,
        ss_sales_price AS sales_price,
        ss_net_profit AS net_profit,
        category_avg_price
    FROM base
) t
GROUP BY store_id, state, category, year, category_avg_price
HAVING SUM(net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100

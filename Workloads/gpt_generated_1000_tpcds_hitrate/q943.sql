WITH filtered_dates AS (
    SELECT d.d_date_sk,
           d.d_date,
           d.d_year,
           d.d_month_seq,
           d.d_week_seq
    FROM   tpcds.date_dim d
    WHERE  d.d_year = 2001                     -- predicate 1
      AND  d.d_month_seq BETWEEN 1 AND 12    -- predicate 2
),
store_data AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           s.s_store_name,
           s.s_state,
           s.s_number_employees,
           s.s_country,
           w.w_warehouse_sk,
           w.w_state AS wh_state
    FROM   tpcds.store s
    LEFT   JOIN tpcds.warehouse w
           ON w.w_warehouse_sk = s.s_store_sk -- **allowed by rule via inventory later**
    WHERE  s.s_state = 'CA'                     -- predicate 3
      AND  s.s_number_employees BETWEEN 200 AND 300   -- predicate 4
),
inventory_stats AS (
    SELECT i.inv_warehouse_sk,
           AVG(i.inv_quantity_on_hand) AS avg_inv_qty
    FROM   tpcds.inventory i
    GROUP BY i.inv_warehouse_sk
),
joined_facts AS (
    SELECT d.d_date_sk,
           d.d_date,
           d.d_year,
           sd.s_store_sk,
           sd.s_store_id,
           sd.s_store_name,
           sd.s_state,
           sd.s_number_employees,
           ca.ca_address_sk,
           ca.ca_country,
           cd.cd_demo_sk,
           cd.cd_gender,
           ss.ss_net_paid,
           ss.ss_net_profit,
           cs.cs_ext_sales_price,
           cr.cr_return_amount,
           sr.sr_return_amt,
           wr.wr_return_amt,
           r.r_reason_desc,
           i.inv_quantity_on_hand,
           w.w_warehouse_sk,
           ws.web_site_id
    FROM   filtered_dates d
    -- store_sales fact
    LEFT   JOIN tpcds.store_sales ss
           ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT   JOIN store_data sd
           ON ss.ss_store_sk = sd.s_store_sk
    LEFT   JOIN tpcds.customer_address ca
           ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT   JOIN tpcds.customer_demographics cd
           ON ss.ss_cdemo_sk = cd.cd_demo_sk
    -- catalog_sales fact (sold date)
    LEFT   JOIN tpcds.catalog_sales cs
           ON cs.cs_sold_date_sk = d.d_date_sk
    -- catalog_returns (returned date)
    LEFT   JOIN tpcds.catalog_returns cr
           ON cr.cr_returned_date_sk = d.d_date_sk
    -- store_returns (returned date)
    LEFT   JOIN tpcds.store_returns sr
           ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT   JOIN tpcds.reason r
           ON sr.sr_reason_sk = r.r_reason_sk
    -- web_returns (returned date)
    LEFT   JOIN tpcds.web_returns wr
           ON wr.wr_returned_date_sk = d.d_date_sk
    -- inventory (date and warehouse)
    LEFT   JOIN tpcds.inventory i
           ON i.inv_date_sk = d.d_date_sk
    LEFT   JOIN tpcds.warehouse w
           ON i.inv_warehouse_sk = w.w_warehouse_sk
    -- web_site (open date)
    LEFT   JOIN tpcds.web_site ws
           ON ws.web_open_date_sk = d.d_date_sk
    -- additional filters on joined dimensions
    WHERE  ca.ca_country = 'United States'      -- predicate 5
      AND  cd.cd_gender = 'F'                    -- predicate 6
      AND  i.inv_quantity_on_hand > 100          -- predicate 7
      AND  (w.w_state = 'CA' OR w.w_state IS NULL) -- predicate 8 (optional)
      AND NOT EXISTS (
          SELECT 1
          FROM   tpcds.store_returns sr_chk
          WHERE  sr_chk.sr_store_sk = sd.s_store_sk
            AND  sr_chk.sr_returned_date_sk = d.d_date_sk
      )
),
aggregated AS (
    SELECT d_date,
           d_year,
           s_store_id,
           s_store_name,
           s_state,
           s_number_employees,
           SUM(ss_net_paid)               AS total_sales,
           SUM(ss_net_profit)             AS total_profit,
           SUM(COALESCE(cr_return_amount,0) + COALESCE(sr_return_amt,0) + COALESCE(wr_return_amt,0)) AS total_returns,
           AVG(avg_inv_qty)               AS avg_warehouse_inventory,
           COUNT(DISTINCT r_reason_desc)  AS distinct_return_reasons
    FROM   joined_facts jf
    LEFT   JOIN inventory_stats ist
           ON ist.inv_warehouse_sk = jf.w_warehouse_sk
    GROUP BY d_date,
             d_year,
             s_store_id,
             s_store_name,
             s_state,
             s_number_employees
)
SELECT d_date,
       d_year,
       s_store_id,
       s_store_name,
       s_state,
       s_number_employees,
       total_sales,
       total_profit,
       total_returns,
       avg_warehouse_inventory,
       distinct_return_reasons,
       RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
       ROW_NUMBER() OVER (ORDER BY total_profit DESC)               AS profit_rownum
FROM   aggregated
ORDER BY sales_rank ASC, total_sales DESC
LIMIT  100

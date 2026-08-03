WITH
    /* Sample a portion of store_sales */
    sampled_store_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    /* Aggregate sales per item and year */
    sales_agg AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_sold_date_sk,
            d.d_year,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit
        FROM sampled_store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, d.d_year
    ),
    /* Aggregate store returns per item and year */
    returns_agg AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            d.d_year,
            SUM(sr.sr_return_amt_inc_tax) AS total_returns,
            SUM(sr.sr_net_loss) AS total_loss,
            r.r_reason_desc AS return_reason
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, d.d_year, r.r_reason_desc
    ),
    /* Aggregate web returns per item and year */
    web_agg AS (
        SELECT
            wr.wr_item_sk,
            d.d_year,
            SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
            COUNT(*) AS web_return_cnt,
            r.r_reason_desc AS web_return_reason
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        GROUP BY wr.wr_item_sk, d.d_year, r.r_reason_desc
    ),
    /* Keep only items that appear in both sales and store returns */
    intersect_keys AS (
        SELECT ss_item_sk AS item_sk, d_year
        FROM sales_agg
        INTERSECT
        SELECT sr_item_sk, d_year
        FROM returns_agg
    ),
    /* Rank customers by total sales per birth country */
    ranked_customers AS (
        SELECT
            c.c_customer_sk,
            c.c_birth_country,
            SUM(ss.ss_ext_sales_price) AS cust_sales,
            ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
        FROM customer c
        JOIN sampled_store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
        WHERE c.c_birth_country IN ('URUGUAY','KOREA','PHILIPPINES','UKRAINE')
        GROUP BY c.c_customer_sk, c.c_birth_country
        HAVING SUM(ss.ss_ext_sales_price) > 1000
    ),
    /* Full outer join between call_center and catalog_sales */
    call_center_sales AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            CASE WHEN cs.cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
        FROM call_center cc
        FULL OUTER JOIN catalog_sales cs
            ON cc.cc_call_center_sk = cs.cs_call_center_sk
        WHERE cc.cc_state = 'CA' OR cs.cs_ext_sales_price > 500
    ),
    /* One row from the full outer join for inclusion in the final result */
    call_center_one AS (
        SELECT *
        FROM (
            SELECT *, ROW_NUMBER() OVER (ORDER BY cs_ext_sales_price DESC NULLS LAST) AS rn
            FROM call_center_sales
        ) t
        WHERE rn = 1
    ),
    /* Combine catalog_sales with its related tables */
    catalog_full AS (
        SELECT
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            w.w_warehouse_name,
            r.r_reason_desc AS catalog_return_reason,
            cc.cc_name AS catalog_cc_name,
            CASE WHEN cr.cr_return_amount > 0 THEN 'RETURNED' ELSE 'NO_RETURN' END AS return_flag
        FROM catalog_sales cs
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cs.cs_ext_sales_price > 200
    ),
    /* Rank items by sales within each category */
    item_rank AS (
        SELECT
            sa.ss_item_sk,
            i.i_category,
            sa.total_sales,
            ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY sa.total_sales DESC) AS sales_rank
        FROM sales_agg sa
        JOIN item i ON sa.ss_item_sk = i.i_item_sk
    )
SELECT
    ik.item_sk,
    ik.d_year,
    sa.total_sales,
    ra.total_returns,
    wa.web_return_total,
    CASE WHEN sa.total_profit > ra.total_loss THEN 'PROFITABLE' ELSE 'LOSS' END AS overall_status,
    rc.c_birth_country,
    rc.cust_sales,
    rc.rn AS cust_rank,
    cf.cs_ext_sales_price AS catalog_sales_price,
    cf.w_warehouse_name,
    cf.catalog_return_reason,
    cf.return_flag,
    ir.sales_rank,
    cc1.cc_name AS call_center_name,
    cc1.profit_flag
FROM intersect_keys ik
JOIN sales_agg sa ON ik.item_sk = sa.ss_item_sk AND ik.d_year = sa.d_year
JOIN returns_agg ra ON ik.item_sk = ra.sr_item_sk AND ik.d_year = ra.d_year
LEFT JOIN web_agg wa ON ik.item_sk = wa.wr_item_sk AND ik.d_year = wa.d_year
LEFT JOIN ranked_customers rc ON rc.rn <= 3
LEFT JOIN catalog_full cf ON cf.cs_item_sk = sa.ss_item_sk AND cf.cs_sold_date_sk = sa.ss_sold_date_sk
LEFT JOIN item_rank ir ON ir.ss_item_sk = sa.ss_item_sk
CROSS JOIN call_center_one cc1
WHERE ik.d_year BETWEEN 1999 AND 2002
  AND ra.return_reason <> 'Damaged'
  AND wa.web_return_reason = 'Customer Not Satisfied'
  AND cc1.profit_flag = 'POSITIVE'
ORDER BY ik.d_year DESC, sa.total_sales DESC, rc.cust_sales DESC
LIMIT 100

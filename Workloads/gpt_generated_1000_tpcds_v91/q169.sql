WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
union_returns AS (
    SELECT
        d.d_year AS year,
        ca.ca_location_type AS location_type,
        CASE WHEN sr.sr_fee > 50 THEN 'HighFee' ELSE 'LowFee' END AS fee_category,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        SUM(ia.total_qty) AS total_inventory_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_address ca_dup ON sr.sr_addr_sk = ca_dup.ca_address_sk
    JOIN inv_agg ia ON sr.sr_returned_date_sk = ia.inv_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_inv1 ON ia.inv_date_sk = d_inv1.d_date_sk
    JOIN date_dim d_inv2 ON ia.inv_date_sk = d_inv2.d_date_sk
    JOIN date_dim d_inv3 ON ia.inv_date_sk = d_inv3.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_location_type = 'single family'
    GROUP BY d.d_year,
             ca.ca_location_type,
             CASE WHEN sr.sr_fee > 50 THEN 'HighFee' ELSE 'LowFee' END
    HAVING SUM(sr.sr_return_amt_inc_tax) > 1000

    UNION

    SELECT
        d.d_year AS year,
        ca_ref.ca_location_type AS location_type,
        CASE WHEN wr.wr_fee > 30 THEN 'HighFee' ELSE 'LowFee' END AS fee_category,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(wr.wr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        SUM(ia.total_qty) AS total_inventory_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN inv_agg ia ON wr.wr_returned_date_sk = ia.inv_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_inv1b ON ia.inv_date_sk = d_inv1b.d_date_sk
    JOIN date_dim d_inv2b ON ia.inv_date_sk = d_inv2b.d_date_sk
    WHERE d.d_year = 2001
      AND ca_ret.ca_location_type = 'condo'
    GROUP BY d.d_year,
             ca_ref.ca_location_type,
             CASE WHEN wr.wr_fee > 30 THEN 'HighFee' ELSE 'LowFee' END
    HAVING SUM(wr.wr_return_amt_inc_tax) > 500
)
SELECT
    year,
    location_type,
    fee_category,
    total_return_inc_tax,
    total_fee,
    return_cnt,
    total_inventory_qty
FROM union_returns
ORDER BY year DESC, total_return_inc_tax DESC
LIMIT 100

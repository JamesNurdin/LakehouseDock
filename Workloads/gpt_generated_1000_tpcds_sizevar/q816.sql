WITH
-- Aggregate sales information from catalog_sales
sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cs.cs_sales_price BETWEEN 20.00 AND 200.00
      AND cs.cs_quantity BETWEEN 1 AND 20
      AND w.w_state = 'CA'
      AND w.w_warehouse_sq_ft >= 100000
      AND hd.hd_income_band_sk IN (7, 13)
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, w.w_warehouse_name, d.d_year
),

-- Aggregate return information from catalog_returns
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 10.00
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND w.w_state = 'CA'
      AND hd.hd_dep_count <= 2
      AND ca.ca_state = 'CA'
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk, w.w_warehouse_name, d.d_year
),

-- Aggregate store‑return information from store_returns
store_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
        AVG(sr.sr_return_amt) AS avg_store_return_amt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 15.00
      AND sr.sr_return_quantity BETWEEN 1 AND 3
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 1
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk, d.d_year
),

-- Full outer join of sales and catalog returns
full_sales_returns AS (
    SELECT
        COALESCE(sa.date_sk, ra.date_sk) AS date_sk,
        COALESCE(sa.item_sk, ra.item_sk) AS item_sk,
        COALESCE(sa.warehouse_name, ra.warehouse_name) AS warehouse_name,
        sa.total_net_paid,
        ra.total_return_amount,
        sa.distinct_orders,
        ra.distinct_return_orders,
        sa.total_quantity,
        ra.total_return_quantity,
        CASE WHEN COALESCE(sa.total_quantity, 0) > 5000 THEN 'HIGH_VOLUME' ELSE 'NORMAL_VOLUME' END AS volume_category,
        CASE WHEN COALESCE(ra.total_return_quantity, 0) > 500 THEN 'HIGH_RETURNS' ELSE 'NORMAL_RETURNS' END AS return_category,
        'sales_return' AS source
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.date_sk = ra.date_sk
       AND sa.item_sk = ra.item_sk
       AND sa.warehouse_name = ra.warehouse_name
),

-- Merge store returns with the previous full outer join
merged_data AS (
    SELECT
        COALESCE(fsr.date_sk, st.date_sk) AS date_sk,
        COALESCE(fsr.item_sk, st.item_sk) AS item_sk,
        fsr.warehouse_name,
        fsr.total_net_paid,
        fsr.total_return_amount,
        st.total_store_return_amt,
        fsr.distinct_orders,
        fsr.distinct_return_orders,
        st.distinct_store_tickets,
        fsr.volume_category,
        fsr.return_category,
        CASE WHEN COALESCE(st.total_store_return_qty, 0) > 200 THEN 'HIGH_STORE_RETURNS' ELSE 'NORMAL_STORE_RETURNS' END AS store_return_category,
        fsr.source
    FROM full_sales_returns fsr
    FULL OUTER JOIN store_agg st
        ON fsr.date_sk = st.date_sk
       AND fsr.item_sk = st.item_sk
),

-- Aggregate web site information (will be UNION‑ed later)
web_agg AS (
    SELECT
        NULL AS date_sk,
        NULL AS item_sk,
        NULL AS warehouse_name,
        NULL AS total_net_paid,
        NULL AS total_return_amount,
        NULL AS total_store_return_amt,
        COUNT(DISTINCT ws.web_site_id) AS distinct_orders,
        NULL AS distinct_return_orders,
        NULL AS distinct_store_tickets,
        CASE WHEN ws.web_tax_percentage > 0.07 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS volume_category,
        NULL AS return_category,
        NULL AS store_return_category,
        ws.web_site_id AS source
    FROM web_site ws
    JOIN date_dim d
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.web_state = 'CA'
      AND ws.web_gmt_offset = -8.00
      AND ws.web_tax_percentage BETWEEN 0.05 AND 0.10
    GROUP BY ws.web_site_id, ws.web_tax_percentage
)
-- Final result set: UNION distinct of merged data and web data, ordered, paged
SELECT
    date_sk,
    item_sk,
    warehouse_name,
    total_net_paid,
    total_return_amount,
    total_store_return_amt,
    distinct_orders,
    distinct_return_orders,
    distinct_store_tickets,
    volume_category,
    return_category,
    store_return_category,
    source
FROM merged_data
UNION DISTINCT
SELECT
    date_sk,
    item_sk,
    warehouse_name,
    total_net_paid,
    total_return_amount,
    total_store_return_amt,
    distinct_orders,
    distinct_return_orders,
    distinct_store_tickets,
    volume_category,
    return_category,
    store_return_category,
    source
FROM web_agg
ORDER BY source DESC
OFFSET 10
LIMIT 100

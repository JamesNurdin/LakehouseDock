WITH
    -- Sample a fraction of the inventory table
    inv_sample AS (
        SELECT inv_date_sk,
               inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    -- Filtered date dimension (used by many joins)
    date_filtered AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq BETWEEN 1 AND 12
    ),
    -- Store side with a LEFT OUTER JOIN to the date dimension
    store_part AS (
        SELECT s.*, d.d_date_sk AS closed_date_sk
        FROM store s
        LEFT JOIN date_filtered d ON s.s_closed_date_sk = d.d_date_sk
    ),
    -- Web site side with a LEFT OUTER JOIN to the date dimension
    website_part AS (
        SELECT w.*, d.d_date_sk AS close_date_sk
        FROM web_site w
        LEFT JOIN date_filtered d ON w.web_close_date_sk = d.d_date_sk
    ),
    -- FULL OUTER JOIN between the two sides, keeping unmatched rows
    store_website_combined AS (
        SELECT COALESCE(st.closed_date_sk, ws.close_date_sk) AS d_date_sk,
               st.s_store_id,
               st.s_store_name,
               ws.web_site_id,
               ws.web_name
        FROM store_part st
        FULL OUTER JOIN website_part ws
            ON st.closed_date_sk = ws.close_date_sk
    ),
    -- Customer joined to demographics and dates
    customer_part AS (
        SELECT c.c_customer_sk,
               c.c_customer_id,
               cd.cd_gender,
               cd.cd_marital_status,
               d.d_year,
               d.d_month_seq
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN date_filtered d ON c.c_first_sales_date_sk = d.d_date_sk
    ),
    -- Catalog returns with several dimensions
    catalog_part AS (
        SELECT cr.cr_order_number,
               cr.cr_return_amount,
               cr.cr_return_quantity,
               cr.cr_net_loss,
               cc.cc_name,
               sm.sm_carrier,
               r.r_reason_desc,
               d.d_year
        FROM catalog_returns cr
        JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > 0
    ),
    -- Store returns with several dimensions
    store_return_part AS (
        SELECT sr.sr_ticket_number,
               sr.sr_return_amt AS sr_return_amount,
               sr.sr_return_quantity,
               sr.sr_net_loss,
               s.s_store_name,
               c.c_customer_id,
               r.r_reason_desc,
               d.d_year
        FROM store_returns sr
        JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_return_amt > 0
    ),
    -- Inventory part (sampled) linked to the date dimension
    inventory_part AS (
        SELECT inv_item_sk AS key_id,
               inv_quantity_on_hand AS amount,
               inv_quantity_on_hand AS qty,
               CAST(NULL AS decimal(7,2)) AS net_loss,
               CAST(NULL AS varchar) AS name,
               CAST(NULL AS varchar) AS carrier,
               CAST(NULL AS varchar) AS reason,
               d.d_year,
               CAST(NULL AS varchar) AS store_name,
               CAST(NULL AS varchar) AS customer_id
        FROM inv_sample inv
        JOIN date_filtered d ON inv.inv_date_sk = d.d_date_sk
        WHERE inv.inv_quantity_on_hand > 0
    ),
    -- Union of the three source streams (catalog, store, inventory)
    combined AS (
        SELECT
            'catalog' AS src,
            cr_order_number AS key_id,
            cr_return_amount AS amount,
            cr_return_quantity AS qty,
            cr_net_loss AS net_loss,
            cc_name AS name,
            sm_carrier AS carrier,
            r_reason_desc AS reason,
            d_year,
            CAST(NULL AS varchar) AS store_name,
            CAST(NULL AS varchar) AS customer_id
        FROM catalog_part

        UNION DISTINCT

        SELECT
            'store' AS src,
            sr_ticket_number AS key_id,
            sr_return_amount AS amount,
            sr_return_quantity AS qty,
            sr_net_loss AS net_loss,
            CAST(NULL AS varchar) AS name,
            CAST(NULL AS varchar) AS carrier,
            r_reason_desc AS reason,
            d_year,
            s_store_name AS store_name,
            c_customer_id AS customer_id
        FROM store_return_part

        UNION DISTINCT

        SELECT
            'inventory' AS src,
            key_id,
            amount,
            qty,
            net_loss,
            name,
            carrier,
            reason,
            d_year,
            store_name,
            customer_id
        FROM inventory_part
    )
SELECT
    c.src,
    c.key_id,
    c.amount,
    c.qty,
    c.net_loss,
    c.name,
    c.carrier,
    c.reason,
    c.d_year,
    c.store_name,
    c.customer_id,
    -- Ranking of amount within each year
    RANK() OVER (PARTITION BY c.d_year ORDER BY c.amount DESC) AS amt_rank,
    -- Cumulative amount per year ordered by amount
    SUM(c.amount) OVER (PARTITION BY c.d_year ORDER BY c.amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount,
    -- Flag high net loss
    CASE WHEN c.net_loss > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
    -- Correlated sub‑query counting rows with the same reason in the same year
    (SELECT COUNT(*)
     FROM combined c2
     WHERE c2.reason = c.reason
       AND c2.d_year = c.d_year) AS same_reason_year_count,
    -- Columns brought in by the FULL OUTER JOIN between store and web_site
    sw.s_store_id,
    sw.web_site_id
FROM combined c
LEFT JOIN store_website_combined sw ON TRUE
LEFT JOIN date_filtered d2 ON sw.d_date_sk = d2.d_date_sk AND c.d_year = d2.d_year
WHERE c.d_year BETWEEN 2000 AND 2002
  AND (c.src = 'catalog' OR c.amount > 50)
  AND c.carrier IS NOT NULL
  AND c.store_name IS NOT NULL
  AND c.customer_id IS NOT NULL
ORDER BY c.d_year DESC, amt_rank
OFFSET 10
LIMIT 100

WITH
    -- Store returns fact, joined to time_dim for a time‑range filter
    sr AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_store_sk,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
            COUNT(*) AS cnt_returns
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17               -- business hours filter
          AND sr.sr_return_quantity > 0
        GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
    ),
    -- Catalog returns fact, joined to warehouse
    cr AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_warehouse_sk,
            SUM(cr.cr_return_amount) AS total_cat_return,
            AVG(cr.cr_fee) AS avg_fee
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
          AND cr.cr_fee > 5.00                        -- fee filter
        GROUP BY cr.cr_returned_date_sk, cr.cr_warehouse_sk
    ),
    -- Web returns fact, joined to customer (refunded side)
    wr AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_refunded_customer_sk,
            SUM(wr.wr_return_amt) AS total_web_return,
            COUNT(*) AS cnt_web
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 0
          AND wr.wr_fee > 10.00                       -- fee filter
        GROUP BY wr.wr_returned_date_sk, wr.wr_refunded_customer_sk
    ),
    -- Union of the three fact sources (distinct rows)
    union_facts AS (
        SELECT sr_returned_date_sk AS d_sk,
               sr_store_sk        AS entity_sk,
               total_return_amt  AS amt,
               cnt_returns       AS cnt,
               'store'   AS src
        FROM sr
        UNION
        SELECT cr_returned_date_sk,
               cr_warehouse_sk,
               total_cat_return,
               NULL,
               'catalog' AS src
        FROM cr
        UNION
        SELECT wr_returned_date_sk,
               wr_refunded_customer_sk,
               total_web_return,
               cnt_web,
               'web'     AS src
        FROM wr
    ),
    -- Demographic dimension (joins several customer related tables)
    cust_dim AS (
        SELECT
            c.c_customer_sk,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            ca.ca_state,
            c.c_birth_year
        FROM customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE c.c_birth_year BETWEEN 1960 AND 1970                -- age filter
    ),
    -- Join the unioned facts to all needed dimensions
    joined AS (
        SELECT
            uf.d_sk,
            d.d_date,
            uf.entity_sk,
            uf.amt,
            uf.cnt,
            uf.src,
            s.s_store_name,
            w.w_warehouse_name,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            ca.ca_state,
            CASE WHEN COALESCE(s.s_state, ca.ca_state) = 'CA' THEN 'West' ELSE 'Other' END AS region,
            -- correlated scalar sub‑query: total catalog return amount for the same date
            (SELECT SUM(cr2.cr_return_amount)
             FROM catalog_returns cr2
             WHERE cr2.cr_returned_date_sk = uf.d_sk) AS cat_ret_sum_for_date
        FROM union_facts uf
        LEFT JOIN date_dim d ON uf.d_sk = d.d_date_sk
        LEFT JOIN store s ON uf.src = 'store'   AND uf.entity_sk = s.s_store_sk
        LEFT JOIN warehouse w ON uf.src = 'catalog' AND uf.entity_sk = w.w_warehouse_sk
        LEFT JOIN customer c ON uf.src = 'web' AND uf.entity_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2002                               -- year filter
          AND d.d_month_seq BETWEEN 1200 AND 1210          -- month‑seq filter
          AND (s.s_state = 'CA' OR ca.ca_state = 'CA')    -- state filter
          AND uf.amt > 0                                  -- positive amount filter
    ),
    -- FULL OUTER JOIN between store and web_site on their closed/open dates
    store_ws AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            ws.web_site_sk,
            ws.web_name,
            d_close.d_date AS close_date,
            CASE WHEN s.s_store_sk IS NULL THEN 'WebOnly'
                 WHEN ws.web_site_sk IS NULL THEN 'StoreOnly'
                 ELSE 'Both' END AS source_flag
        FROM store s
        FULL OUTER JOIN web_site ws
            ON s.s_closed_date_sk = ws.web_close_date_sk
        LEFT JOIN date_dim d_close ON (
                s.s_closed_date_sk = d_close.d_date_sk OR
                ws.web_close_date_sk = d_close.d_date_sk)
        WHERE (s.s_state = 'TX' OR ws.web_state = 'TX')
    ),
    -- Customers that never appeared as a returning customer in catalog_returns (anti‑semi join)
    active_customers AS (
        SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
        FROM customer c
        WHERE c.c_customer_sk NOT IN (
            SELECT cr.cr_returning_customer_sk
            FROM catalog_returns cr
            WHERE cr.cr_returned_date_sk = (
                SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2002-01-15'
            )
        )
    ),
    -- EXCEPT: stores that are closed but do NOT have a matching catalog page start key
    store_excluding AS (
        SELECT s.s_store_sk
        FROM store s
        WHERE s.s_closed_date_sk IS NOT NULL
        EXCEPT
        SELECT cp.cp_catalog_page_sk
        FROM catalog_page cp
        WHERE cp.cp_start_date_sk IS NOT NULL
    )
SELECT
    j.d_date,
    j.region,
    SUM(j.amt)                     AS total_amount,
    AVG(j.cnt)                     AS avg_cnt,
    MIN(j.amt)                     AS min_amount,
    MAX(j.amt)                     AS max_amount,
    COUNT(DISTINCT j.entity_sk)    AS distinct_entities,
    SUM(j.cat_ret_sum_for_date)    AS total_catalog_return_amount,
    COUNT(*) FILTER (WHERE j.src = 'store')   AS store_rows,
    COUNT(*) FILTER (WHERE j.src = 'catalog') AS catalog_rows,
    COUNT(*) FILTER (WHERE j.src = 'web')    AS web_rows
FROM joined j
GROUP BY j.d_date, j.region
HAVING SUM(j.amt) > 1000                     -- having filter
ORDER BY total_amount DESC
LIMIT 100

WITH
    -- Small computed set of hours for the cross join
    hours AS (
        SELECT 9 AS hour
        UNION ALL SELECT 15 AS hour
    ),
    -- Catalog sales excluding orders that have a catalog return (anti‑semi join)
    catalog_sales_filtered AS (
        SELECT cs.*
        FROM catalog_sales cs
        WHERE cs.cs_order_number NOT IN (
            SELECT cr.cr_order_number
            FROM catalog_returns cr
        )
    ),
    -- Web sales excluding orders that have a web return (anti‑semi join)
    web_sales_filtered AS (
        SELECT ws.*
        FROM web_sales ws
        WHERE ws.ws_order_number NOT IN (
            SELECT wr.wr_order_number
            FROM web_returns wr
        )
    ),
    -- Join catalog sales with all required dimensions and apply filters
    catalog_sales_joined AS (
        SELECT
            csf.cs_order_number            AS order_number,
            d.d_year,
            t.t_hour,
            p.p_promo_id,
            cp.cp_department,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_upper_bound,
            csf.cs_net_paid               AS net_paid,
            csf.cs_net_profit             AS net_profit,
            c.c_preferred_cust_flag,
            ca.ca_state
        FROM catalog_sales_filtered csf
        JOIN date_dim d ON csf.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON csf.cs_sold_time_sk = t.t_time_sk
        JOIN promotion p ON csf.cs_promo_sk = p.p_promo_sk
        JOIN catalog_page cp ON csf.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c ON csf.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON csf.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON csf.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON csf.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
          AND t.t_hour = 9
          AND p.p_discount_active = 'Y'
          AND cp.cp_department = 'Electronics'
          AND ib.ib_upper_bound = 150000
          AND hd.hd_buy_potential = '5000-9999'
          AND c.c_preferred_cust_flag = 'Y'
          AND ca.ca_state = 'TX'
    ),
    -- Join web sales with all required dimensions and apply the same filters
    web_sales_joined AS (
        SELECT
            wsf.ws_order_number            AS order_number,
            d.d_year,
            t.t_hour,
            p.p_promo_id,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_upper_bound,
            wsf.ws_net_paid               AS net_paid,
            wsf.ws_net_profit             AS net_profit,
            c.c_preferred_cust_flag,
            ca.ca_state
        FROM web_sales_filtered wsf
        JOIN date_dim d ON wsf.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON wsf.ws_sold_time_sk = t.t_time_sk
        JOIN promotion p ON wsf.ws_promo_sk = p.p_promo_sk
        JOIN customer c ON wsf.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON wsf.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON wsf.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON wsf.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
          AND t.t_hour = 9
          AND p.p_discount_active = 'Y'
          AND ib.ib_upper_bound = 150000
          AND hd.hd_buy_potential = '5000-9999'
          AND c.c_preferred_cust_flag = 'Y'
          AND ca.ca_state = 'TX'
    ),
    -- Combine catalog and web sales (set operation)
    combined_sales AS (
        SELECT order_number, d_year, t_hour, p_promo_id, net_paid, net_profit
        FROM catalog_sales_joined
        UNION ALL
        SELECT order_number, d_year, t_hour, p_promo_id, net_paid, net_profit
        FROM web_sales_joined
    ),
    -- Aggregate the combined sales; window function will be applied later
    sales_aggregated AS (
        SELECT
            p_promo_id,
            d_year,
            t_hour,
            SUM(net_paid)   AS total_net_paid,
            SUM(net_profit) AS total_net_profit,
            COUNT(*)        AS order_count
        FROM combined_sales
        GROUP BY p_promo_id, d_year, t_hour
    ),
    -- Sample a fraction of store returns (10% Bernoulli)
    store_returns_sampled AS (
        SELECT sr.*
        FROM store_returns sr TABLESAMPLE BERNOULLI (10)
    ),
    -- Join sampled store returns with dimensions and filter on reason
    store_returns_joined AS (
        SELECT
            sr.sr_returned_date_sk,
            d.d_year,
            t.t_hour,
            r.r_reason_desc,
            sr.sr_net_loss
        FROM store_returns_sampled sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc = 'Damaged'
          AND d.d_year = 2001
    )
SELECT
    sa.p_promo_id,
    sa.d_year,
    sa.t_hour,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.order_count,
    ROW_NUMBER() OVER (PARTITION BY sa.p_promo_id ORDER BY sa.total_net_profit DESC) AS profit_rank,
    COALESCE(srj.sr_net_loss, 0)                             AS total_store_net_loss,
    ib.ib_income_band_sk,
    ib.ib_upper_bound,
    h.hour                                                   AS cross_hour
FROM sales_aggregated sa
LEFT JOIN store_returns_joined srj
    ON sa.d_year = srj.d_year AND sa.t_hour = srj.t_hour
-- Cross join a small income‑band slice with the hours set
CROSS JOIN (
    SELECT ib_income_band_sk, ib_upper_bound
    FROM income_band
    WHERE ib_upper_bound = 150000
) ib
CROSS JOIN (
    SELECT hour FROM hours
) h
ORDER BY sa.total_net_profit DESC

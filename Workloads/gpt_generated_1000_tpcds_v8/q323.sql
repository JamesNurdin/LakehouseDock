WITH
    /* Sales fact joined to all dimensions */
    sales_base AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_cdemo_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            d_sales.d_date,
            i.i_brand,
            i.i_category,
            c.c_first_name,
            cd.cd_gender,
            hd.hd_buy_potential,
            ca.ca_state
        FROM store_sales ss
        JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d_sales.d_year = 2001
    ),
    /* Returns fact joined to all dimensions */
    returns_base AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_refunded_customer_sk,
            wr.wr_refunded_cdemo_sk,
            wr.wr_refunded_hdemo_sk,
            wr.wr_refunded_addr_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            d_ret.d_date,
            i_ret.i_brand,
            i_ret.i_category,
            c_ret.c_first_name,
            cd_ret.cd_gender,
            hd_ret.hd_buy_potential,
            ca_ret.ca_state,
            r.r_reason_desc
        FROM web_returns wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN item i_ret ON wr.wr_item_sk = i_ret.i_item_sk
        JOIN customer c_ret ON wr.wr_refunded_customer_sk = c_ret.c_customer_sk
        JOIN customer_demographics cd_ret ON wr.wr_refunded_cdemo_sk = cd_ret.cd_demo_sk
        JOIN household_demographics hd_ret ON wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
        JOIN customer_address ca_ret ON wr.wr_refunded_addr_sk = ca_ret.ca_address_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE d_ret.d_year = 2001
    ),
    /* Full outer join of the two fact bases – keeps unmatched rows from both sides */
    full_joined AS (
        SELECT
            COALESCE(s.ss_item_sk, r.wr_item_sk) AS item_sk,
            COALESCE(s.d_date, r.d_date) AS trans_date,
            COALESCE(s.ss_quantity, 0) - COALESCE(r.wr_return_quantity, 0) AS net_quantity,
            COALESCE(s.ss_net_paid, 0) - COALESCE(r.wr_return_amt, 0) AS net_amount,
            COALESCE(s.i_brand, r.i_brand) AS brand,
            COALESCE(s.i_category, r.i_category) AS category,
            COALESCE(s.c_first_name, r.c_first_name) AS customer_first_name,
            COALESCE(s.cd_gender, r.cd_gender) AS gender,
            COALESCE(s.hd_buy_potential, r.hd_buy_potential) AS buy_potential,
            COALESCE(s.ca_state, r.ca_state) AS state,
            r.r_reason_desc AS return_reason,
            CASE
                WHEN s.ss_item_sk IS NOT NULL AND r.wr_item_sk IS NULL THEN 'sale_only'
                WHEN s.ss_item_sk IS NULL AND r.wr_item_sk IS NOT NULL THEN 'return_only'
                ELSE 'both'
            END AS trans_type
        FROM sales_base s
        FULL OUTER JOIN returns_base r
            ON s.ss_item_sk = r.wr_item_sk
            AND s.d_date = r.d_date
    ),
    /* Union of sales (as positive rows) and returns (as negative rows) */
    combined AS (
        SELECT
            ss_item_sk AS item_sk,
            d_date AS trans_date,
            ss_quantity AS quantity,
            ss_net_paid AS net_amount,
            i_brand AS brand,
            i_category AS category,
            c_first_name AS customer_first_name,
            cd_gender AS gender,
            hd_buy_potential AS buy_potential,
            ca_state AS state,
            NULL AS return_reason,
            'sale' AS trans_type
        FROM sales_base
        UNION DISTINCT
        SELECT
            wr_item_sk,
            d_date,
            -wr_return_quantity,
            -wr_return_amt,
            i_brand,
            i_category,
            c_first_name,
            cd_gender,
            hd_buy_potential,
            ca_state,
            r_reason_desc,
            'return' AS trans_type
        FROM returns_base
    ),
    /* Distinct list of item keys that appear in the union */
    dedup_items AS (
        SELECT DISTINCT item_sk FROM combined
    ),
    /* Items that exist in the master item table but never appear in the union */
    excluded_items AS (
        SELECT i_item_sk FROM item
        EXCEPT
        SELECT item_sk FROM dedup_items
    ),
    /* Aggregate net amount per brand/category/state, ignoring excluded items */
    aggregated AS (
        SELECT
            c.brand,
            c.category,
            c.state,
            SUM(c.net_amount) AS total_net,
            COUNT(*) AS txn_count
        FROM combined c
        LEFT JOIN excluded_items ei ON c.item_sk = ei.i_item_sk
        WHERE ei.i_item_sk IS NULL
        GROUP BY c.brand, c.category, c.state
    )
SELECT
    brand,
    category,
    state,
    total_net,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_net DESC) AS brand_rank
FROM aggregated
ORDER BY total_net DESC
LIMIT 100

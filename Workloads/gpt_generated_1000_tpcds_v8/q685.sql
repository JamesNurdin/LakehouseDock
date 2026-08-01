WITH
    /* Items sold via catalog */
    catalog_items AS (
        SELECT cs_item_sk AS item_sk
        FROM catalog_sales
        WHERE cs_quantity > 0
    ),
    /* Items sold via web */
    web_items AS (
        SELECT ws_item_sk AS item_sk
        FROM web_sales
        WHERE ws_quantity > 0
    ),
    /* Union of the two sales streams (keeps duplicates) */
    union_items AS (
        SELECT item_sk FROM catalog_items
        UNION ALL
        SELECT item_sk FROM web_items
    ),
    /* Items that appear in BOTH catalog and web sales */
    intersect_items AS (
        SELECT item_sk FROM catalog_items
        INTERSECT
        SELECT item_sk FROM web_items
    ),
    /* Aggregate sales information per item */
    sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            COALESCE(SUM(cs.cs_ext_sales_price), 0) AS catalog_sales,
            COALESCE(SUM(ws.ws_ext_sales_price), 0) AS web_sales,
            CASE
                WHEN COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) > 0 THEN 'Profit'
                ELSE 'Loss'
            END AS profit_flag
        FROM intersect_items ii
        JOIN item i ON ii.item_sk = i.i_item_sk
        LEFT JOIN catalog_sales cs ON ii.item_sk = cs.cs_item_sk
        LEFT JOIN web_sales ws ON ii.item_sk = ws.ws_item_sk
        GROUP BY i.i_item_sk, i.i_product_name
    ),
    /* Aggregate return information per item */
    returns_agg AS (
        SELECT
            i.i_item_sk,
            COALESCE(SUM(cr.cr_return_amount), 0) AS catalog_returns,
            COALESCE(SUM(wr.wr_return_amt), 0) AS web_returns
        FROM intersect_items ii
        JOIN item i ON ii.item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON ii.item_sk = cr.cr_item_sk
        LEFT JOIN web_returns wr ON ii.item_sk = wr.wr_item_sk
        GROUP BY i.i_item_sk
    ),
    /* Combine sales and returns, keeping unmatched rows from both sides */
    full_data AS (
        SELECT
            s.i_item_sk,
            s.i_product_name,
            s.catalog_sales,
            s.web_sales,
            r.catalog_returns,
            r.web_returns,
            s.profit_flag
        FROM sales_agg s
        FULL OUTER JOIN returns_agg r ON s.i_item_sk = r.i_item_sk
    ),
    /* Exclude items that have any promotion (anti‑join) */
    filtered_data AS (
        SELECT *
        FROM full_data fd
        WHERE NOT EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = fd.i_item_sk
        )
    ),
    /* Add a constant dimension via a CROSS JOIN */
    cross_joined AS (
        SELECT fd.*, const.grp
        FROM filtered_data fd
        CROSS JOIN (SELECT 'All' AS grp) const
    )
SELECT
    cd.i_item_sk,
    cd.i_product_name,
    cd.catalog_sales,
    cd.web_sales,
    cd.catalog_returns,
    cd.web_returns,
    cd.profit_flag,
    cd.grp
FROM cross_joined cd
ORDER BY cd.profit_flag DESC, cd.i_item_sk
LIMIT 100

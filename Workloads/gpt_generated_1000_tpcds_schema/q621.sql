WITH
    returns_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            d.d_year,
            r.r_reason_desc,
            cr.cr_order_number,
            cr.cr_item_sk,
            cr.cr_return_amount,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amount DESC) AS rn_return
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),
    sales_agg AS (
        SELECT
            ws.ws_sold_date_sk,
            d.d_year,
            sm.sm_type,
            ws.ws_order_number,
            ws.ws_item_sk,
            ws.ws_ext_sales_price,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_ext_sales_price DESC) AS rn_sales
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    ),
    intersect_orders AS (
        SELECT cr_order_number AS order_number FROM returns_agg
        INTERSECT
        SELECT ws_order_number FROM sales_agg
    ),
    full_joined AS (
        SELECT
            COALESCE(r.cr_order_number, s.ws_order_number) AS order_number,
            r.d_year AS return_year,
            s.d_year AS sales_year,
            r.r_reason_desc,
            s.sm_type,
            r.cr_return_amount,
            s.ws_ext_sales_price,
            COALESCE(r.cr_item_sk, s.ws_item_sk) AS item_sk,
            COALESCE(r.cr_returned_date_sk, s.ws_sold_date_sk) AS date_sk
        FROM returns_agg r
        FULL OUTER JOIN sales_agg s
            ON r.cr_order_number = s.ws_order_number
    ),
    final_agg AS (
        SELECT
            fj.order_number,
            fj.item_sk,
            fj.date_sk,
            fj.return_year,
            fj.sales_year,
            fj.r_reason_desc,
            fj.sm_type,
            fj.cr_return_amount,
            fj.ws_ext_sales_price,
            (
                SELECT SUM(inv_quantity_on_hand)
                FROM inventory inv
                WHERE inv.inv_item_sk = fj.item_sk
                  AND inv.inv_date_sk = fj.date_sk
            ) AS total_inventory_on_hand,
            ROW_NUMBER() OVER (ORDER BY (
                SELECT SUM(inv_quantity_on_hand)
                FROM inventory inv
                WHERE inv.inv_item_sk = fj.item_sk
                  AND inv.inv_date_sk = fj.date_sk
            ) DESC) AS global_rn
        FROM full_joined fj
        WHERE fj.order_number IN (SELECT order_number FROM intersect_orders)
    )
SELECT
    fa.return_year,
    fa.sales_year,
    fa.r_reason_desc,
    fa.sm_type,
    COUNT(*) AS order_cnt,
    SUM(fa.cr_return_amount) AS total_return_amount,
    SUM(fa.ws_ext_sales_price) AS total_sales_price,
    SUM(fa.total_inventory_on_hand) AS total_inventory_on_hand,
    MAX(fa.global_rn) AS max_global_rn
FROM final_agg fa
GROUP BY CUBE (fa.return_year, fa.sales_year, fa.r_reason_desc, fa.sm_type)
ORDER BY total_sales_price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

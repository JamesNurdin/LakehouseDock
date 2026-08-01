WITH
    base AS (
        SELECT
            cc.cc_call_center_sk,
            cr.cr_item_sk,
            dr.d_year AS dr_year,
            i.i_category,
            ws.ws_net_paid,
            ls.total_sales
        FROM catalog_returns cr
        JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = dr.d_date_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_date_sk = dr.d_date_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_date_sk = dr.d_date_sk
        CROSS JOIN LATERAL (
            SELECT sum(ws2.ws_ext_sales_price) AS total_sales
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = i.i_item_sk
              AND ws2.ws_sold_date_sk = dr.d_date_sk
        ) ls
        WHERE cr.cr_return_amount > 100
    ),
    store_agg AS (
        SELECT
            i.i_item_sk,
            d.d_year,
            sum(sr.sr_net_loss) AS store_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, d.d_year
    ),
    web_agg AS (
        SELECT
            i.i_item_sk,
            d.d_year,
            sum(wr.wr_net_loss) AS web_net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, d.d_year
    ),
    union_agg AS (
        SELECT i_item_sk, d_year, store_net_loss AS net_loss, 'store' AS src
        FROM store_agg
        UNION DISTINCT
        SELECT i_item_sk, d_year, web_net_loss AS net_loss, 'web' AS src
        FROM web_agg
    ),
    cc_closed AS (
        SELECT cc.cc_call_center_sk, d.d_year AS closed_year
        FROM call_center cc
        JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    ),
    final AS (
        SELECT
            b.cc_call_center_sk,
            b.cr_item_sk,
            b.dr_year,
            b.i_category,
            b.ws_net_paid,
            b.total_sales,
            ua.net_loss,
            ua.src,
            ROW_NUMBER() OVER (PARTITION BY b.cr_item_sk ORDER BY b.dr_year DESC) AS rank_item_year,
            c.closed_year
        FROM base b
        FULL OUTER JOIN union_agg ua
            ON b.cr_item_sk = ua.i_item_sk
           AND b.dr_year = ua.d_year
        LEFT JOIN cc_closed c
            ON b.cc_call_center_sk = c.cc_call_center_sk
        WHERE NOT EXISTS (
                SELECT 1
                FROM store_returns sr2
                WHERE sr2.sr_item_sk = b.cr_item_sk
                  AND sr2.sr_net_loss > 0
            )
          AND b.cc_call_center_sk NOT IN (
                SELECT cc2.cc_call_center_sk
                FROM call_center cc2
                WHERE cc2.cc_state = 'CA'
            )
    )
SELECT
    cc_call_center_sk,
    cr_item_sk,
    dr_year,
    i_category,
    ws_net_paid,
    total_sales,
    net_loss,
    src,
    rank_item_year,
    closed_year
FROM final
WHERE rank_item_year <= 5
ORDER BY dr_year DESC, net_loss DESC
LIMIT 100

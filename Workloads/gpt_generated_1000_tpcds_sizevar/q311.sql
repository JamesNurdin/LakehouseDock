WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        cc1.cc_name,
        cp1.cp_department,
        ws.web_name,
        sr.sr_return_quantity,
        r.r_reason_desc,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_sold_date_sk) AS rn_order,
        SUM(cs.cs_net_paid) OVER (
            PARTITION BY cc1.cc_call_center_sk
            ORDER BY cs.cs_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_net_paid,
        LAG(cs.cs_net_paid) OVER (
            PARTITION BY cc1.cc_call_center_sk
            ORDER BY cs.cs_sold_date_sk
        ) AS lag_net_paid
    FROM
        catalog_sales cs
        LEFT JOIN call_center cc1
            ON cs.cs_call_center_sk = cc1.cc_call_center_sk
        LEFT JOIN catalog_page cp1
            ON cs.cs_catalog_page_sk = cp1.cp_catalog_page_sk
        LEFT JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        LEFT JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        LEFT JOIN date_dim d_open
            ON cs.cs_sold_date_sk = d_open.d_date_sk
        LEFT JOIN web_site ws
            ON ws.web_open_date_sk = d_open.d_date_sk
        LEFT JOIN date_dim d_close
            ON ws.web_close_date_sk = d_close.d_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_returned_date_sk = d_sold.d_date_sk
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim d_closed
            ON cc1.cc_closed_date_sk = d_closed.d_date_sk
    WHERE
        cs.cs_net_paid > (
            SELECT AVG(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d_sold.d_date_sk
        )
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = cp1.cp_department
              AND cp2.cp_catalog_page_sk <> cp1.cp_catalog_page_sk
        )
        AND cs.cs_item_sk IN (
            SELECT sr2.sr_item_sk
            FROM store_returns sr2
            WHERE sr2.sr_return_quantity > 0
        )
        AND ws.web_name = 'OnlineRetail'
        AND d_sold.d_year = 2002
        AND cp1.cp_catalog_page_sk IN (
            SELECT cp3.cp_catalog_page_sk
            FROM catalog_page cp3 TABLESAMPLE BERNOULLI (10)
            WHERE cp3.cp_type = 'A'
        )
),
sub_a AS (
    SELECT cs_order_number, cs_net_paid, rn_order
    FROM joined
    WHERE rn_order <= 5
),
sub_b AS (
    SELECT cs_order_number, cs_net_paid, rn_order
    FROM joined
    WHERE cs_net_paid > 0
)
SELECT *
FROM sub_a
INTERSECT
SELECT *
FROM sub_b
LIMIT 100

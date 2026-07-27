WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        cc.cc_county AS cc_county,
        s.s_state AS s_state,
        ws.web_market_manager AS web_market_manager,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        wr.wr_return_amt AS wr_return_amt,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS return_category
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE cc.cc_county = 'Barrow County'
      AND d.d_year = 2001
      AND s.s_state = 'CA'
      AND ws.web_market_manager = 'John Doe'
      AND inv.inv_quantity_on_hand > 1000
      AND d.d_month_seq BETWEEN 1 AND 12
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        cc_county,
        s_state,
        web_market_manager,
        return_category,
        COUNT(*) AS txn_count,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        SUM(CASE WHEN return_category = 'High' THEN cr_return_amount ELSE 0 END) AS high_return_sum
    FROM base
    GROUP BY
        d_year,
        d_month_seq,
        cc_county,
        s_state,
        web_market_manager,
        return_category
)
SELECT
    d_year,
    d_month_seq,
    cc_county,
    s_state,
    web_market_manager,
    return_category,
    txn_count,
    total_catalog_return,
    total_store_return,
    total_web_return,
    avg_inventory,
    high_return_sum,
    SUM(total_catalog_return) OVER (
        PARTITION BY cc_county
        ORDER BY d_year, d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_catalog_return_by_county
FROM agg
ORDER BY d_year, d_month_seq
LIMIT 100

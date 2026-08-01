WITH joined AS (
    SELECT
        d.d_year,
        s.s_division_id,
        i.i_category,
        r.r_reason_desc,
        ca_sr.ca_zip,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        p.p_cost,
        ws.web_state
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
        AND cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_division_id = 1
      AND i.i_category = 'Jewelry'
      AND p.p_cost BETWEEN 10 AND 1000
      AND ca_sr.ca_zip LIKE '6%'
      AND ws.web_state = 'CA'
      AND r.r_reason_desc = 'Customer Not Satisfied'
),
agg AS (
    SELECT
        d_year,
        s_division_id,
        i_category,
        SUM(store_net_loss) AS total_store_loss,
        SUM(web_net_loss) AS total_web_loss,
        COUNT(*) AS txn_cnt
    FROM joined
    GROUP BY ROLLUP (d_year, s_division_id, i_category)
)
SELECT
    d_year,
    s_division_id,
    NULL AS i_category,
    total_store_loss AS total_loss,
    'Store' AS source
FROM agg
WHERE i_category IS NULL AND s_division_id IS NOT NULL
UNION ALL
SELECT
    d_year,
    NULL AS s_division_id,
    i_category,
    total_web_loss AS total_loss,
    'Web' AS source
FROM agg
WHERE s_division_id IS NULL AND i_category IS NOT NULL
ORDER BY d_year, source, total_loss DESC

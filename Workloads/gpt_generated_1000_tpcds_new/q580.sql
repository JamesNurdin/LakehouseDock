WITH store_agg AS (
    SELECT
        r.r_reason_desc,
        ca.ca_county,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        r.r_reason_desc IN ('Did not like the color', 'Package was damaged')
        AND ca.ca_county IN ('Taos County', 'Barry County')
        AND ca.ca_zip LIKE '9%'
        AND sr.sr_return_amt > 10
        AND EXISTS (SELECT 1 FROM store_returns sr2
                    WHERE sr2.sr_addr_sk = ca.ca_address_sk
                      AND sr2.sr_return_quantity > 1)
    GROUP BY r.r_reason_desc, ca.ca_county
),
web_agg AS (
    SELECT
        r.r_reason_desc,
        ca.ca_county,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        r.r_reason_desc IN ('Did not like the color', 'Package was damaged')
        AND ca.ca_county IN ('Taos County', 'Barry County')
        AND wp.wp_type = 'article'
        AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
        AND wr.wr_return_amt > 5
    GROUP BY r.r_reason_desc, ca.ca_county
),
unioned AS (
    SELECT r_reason_desc, ca_county, net_loss, cnt FROM store_agg
    UNION
    SELECT r_reason_desc, ca_county, net_loss, cnt FROM web_agg
),
combined AS (
    SELECT
        r_reason_desc,
        ca_county,
        SUM(net_loss) AS total_net_loss,
        SUM(cnt) AS total_cnt
    FROM unioned
    GROUP BY r_reason_desc, ca_county
    HAVING SUM(net_loss) > (
        SELECT AVG(t.inner_total) FROM (
            SELECT SUM(net_loss) AS inner_total
            FROM unioned
            GROUP BY r_reason_desc, ca_county
        ) t
    )
)
SELECT
    r_reason_desc,
    ca_county,
    total_net_loss,
    total_cnt
FROM (
    SELECT
        r_reason_desc,
        ca_county,
        total_net_loss,
        total_cnt,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS rn
    FROM combined
) ranked
WHERE rn <= 5
ORDER BY r_reason_desc, total_net_loss DESC
LIMIT 100

WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        ca.ca_address_sk,
        ca.ca_suite_number,
        i.i_item_id,
        i.i_item_sk,
        s.s_store_id,
        s.s_store_sk,
        s.s_state,
        d_ret.d_year,
        sr.sr_net_loss,
        ws.ws_net_profit
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2001 AND 2003
      AND i.i_brand = 'Brand1'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        c_customer_id,
        i_item_id,
        s_store_id,
        d_year,
        SUM(sr_net_loss) AS total_return_net_loss,
        SUM(ws_net_profit) AS total_web_profit,
        c_customer_sk,
        s_state,
        ca_suite_number
    FROM base
    GROUP BY
        ROLLUP (c_customer_id, i_item_id, s_store_id, d_year),
        c_customer_sk,
        s_state,
        ca_suite_number
    HAVING SUM(sr_net_loss) > (
        SELECT AVG(sr2.sr_net_loss)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c_customer_sk
    )
)
SELECT
    a.c_customer_id,
    a.i_item_id,
    a.s_store_id,
    a.d_year,
    a.total_return_net_loss,
    a.total_web_profit,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_net_loss DESC) AS loss_rank_year,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = a.s_state) AS stores_in_state,
    suite_part
FROM agg a
CROSS JOIN UNNEST(split(a.ca_suite_number, ' ')) AS t (suite_part)
ORDER BY a.d_year, loss_rank_year
LIMIT 100

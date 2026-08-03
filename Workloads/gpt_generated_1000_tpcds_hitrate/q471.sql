WITH base AS (
    SELECT
        D.d_year AS d_year,
        C.c_birth_month AS birth_month,
        W.w_state AS state,
        P.p_promo_name AS promo_name,
        WR.wr_return_quantity,
        WR.wr_return_amt,
        WR.wr_order_number,
        C.c_customer_sk,
        C.c_customer_id,
        IB.ib_income_band_sk,
        I.inv_item_sk,
        -- correlated scalar subquery: total return amount for the refunded customer
        (SELECT SUM(wr2.wr_return_amt)
         FROM web_returns wr2
         WHERE wr2.wr_refunded_customer_sk = C.c_customer_sk) AS cust_total_return_amt
    FROM web_returns WR
    JOIN date_dim D
        ON WR.wr_returned_date_sk = D.d_date_sk
    JOIN customer C
        ON WR.wr_refunded_customer_sk = C.c_customer_sk
    JOIN household_demographics HD
        ON C.c_current_hdemo_sk = HD.hd_demo_sk
    JOIN income_band IB
        ON HD.hd_income_band_sk = IB.ib_income_band_sk
    JOIN inventory I
        ON I.inv_date_sk = D.d_date_sk
    JOIN warehouse W
        ON I.inv_warehouse_sk = W.w_warehouse_sk
    JOIN promotion P
        ON P.p_start_date_sk = D.d_date_sk
    JOIN web_page WP
        ON WR.wr_web_page_sk = WP.wp_web_page_sk
    JOIN web_site WS
        ON WS.web_open_date_sk = D.d_date_sk
    WHERE
        D.d_year = 2001                         -- filter 1
        AND C.c_birth_month = 5                 -- filter 2
        AND IB.ib_lower_bound >= 60000          -- filter 3
        AND P.p_discount_active = 'Y'           -- filter 4
        AND I.inv_item_sk NOT IN (
            SELECT inv_item_sk
            FROM inventory
            WHERE inv_quantity_on_hand = 0
        )                                        -- anti‑semi‑join filter
),
agg AS (
    SELECT
        d_year,
        birth_month,
        state,
        promo_name,
        COUNT(*) AS cnt_returns,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt) AS avg_return_amt,
        MIN(wr_return_amt) AS min_return_amt,
        MAX(wr_return_amt) AS max_return_amt,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(DISTINCT ib_income_band_sk) AS distinct_income_bands,
        MAX(cust_total_return_amt) AS max_cust_total_return
    FROM base
    GROUP BY CUBE (d_year, birth_month, state, promo_name)
)
SELECT
    d_year,
    birth_month,
    state,
    promo_name,
    cnt_returns,
    total_return_amt,
    avg_return_amt,
    min_return_amt,
    max_return_amt,
    distinct_customers,
    distinct_income_bands,
    max_cust_total_return,
    rn
FROM (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (
            PARTITION BY a.d_year, a.birth_month, a.state, a.promo_name
            ORDER BY a.total_return_amt DESC
        ) AS rn
    FROM agg a
) t
WHERE rn <= 5                     -- top‑5 per cube cell
ORDER BY d_year DESC, total_return_amt DESC
LIMIT 100

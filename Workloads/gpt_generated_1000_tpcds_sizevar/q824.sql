WITH
    /* Sample a fraction of the store sales fact */
    ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    /* Sample a fraction of the web sales fact */
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    /* Sample a fraction of the catalog sales fact */
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    /* Store‑sales side with full outer join to its returns */
    store_part AS (
        SELECT
            s.ss_sold_date_sk                     AS sold_date_sk,
            c.c_customer_id                       AS customer_id,
            ca.ca_state                           AS state,
            p.p_promo_id                          AS promo_id,
            s.ss_net_paid                         AS net_paid,
            s.ss_net_profit                       AS net_profit,
            CASE WHEN s.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
            (
                SELECT SUM(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_customer_sk = c.c_customer_sk
            )                                     AS total_return_amt,
            RANK() OVER (PARTITION BY p.p_promo_id ORDER BY s.ss_net_paid DESC) AS promo_sales_rank
        FROM ss_sample s
        JOIN customer c               ON s.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca      ON s.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p              ON s.ss_promo_sk = p.p_promo_sk
        FULL OUTER JOIN store_returns sr
            ON s.ss_ticket_number = sr.sr_ticket_number
           AND s.ss_item_sk       = sr.sr_item_sk
        WHERE s.ss_sold_date_sk BETWEEN 2451910 AND 2451915
          AND s.ss_quantity > 1
          AND s.ss_net_paid > 100
          AND ca.ca_country = 'United States'
    ),
    /* Web‑sales side with full outer join to its returns */
    web_part AS (
        SELECT
            w.ws_sold_date_sk                     AS sold_date_sk,
            c.c_customer_id                       AS customer_id,
            ca.ca_state                           AS state,
            p.p_promo_id                          AS promo_id,
            w.ws_net_paid                         AS net_paid,
            w.ws_net_profit                       AS net_profit,
            CASE WHEN w.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
            (
                SELECT SUM(wr2.wr_return_amt)
                FROM web_returns wr2
                WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
            )                                     AS total_return_amt,
            RANK() OVER (PARTITION BY p.p_promo_id ORDER BY w.ws_net_paid DESC) AS promo_sales_rank
        FROM ws_sample w
        JOIN customer c               ON w.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca      ON w.ws_bill_addr_sk = ca.ca_address_sk
        JOIN promotion p              ON w.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm             ON w.ws_ship_mode_sk = sm.sm_ship_mode_sk
        FULL OUTER JOIN web_returns wr
            ON w.ws_order_number = wr.wr_order_number
           AND w.ws_item_sk      = wr.wr_item_sk
        WHERE w.ws_sold_date_sk BETWEEN 2451910 AND 2451915
          AND w.ws_quantity > 1
          AND w.ws_net_paid > 100
          AND ca.ca_country = 'United States'
    ),
    /* Catalog‑sales side (no returns) */
    catalog_part AS (
        SELECT
            c.cs_sold_date_sk                     AS sold_date_sk,
            cust.c_customer_id                    AS customer_id,
            ca.ca_state                           AS state,
            promo.p_promo_id                      AS promo_id,
            c.cs_net_paid                         AS net_paid,
            c.cs_net_profit                       AS net_profit,
            CASE WHEN c.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
            CAST(NULL AS decimal(7,2))            AS total_return_amt,
            RANK() OVER (PARTITION BY promo.p_promo_id ORDER BY c.cs_net_paid DESC) AS promo_sales_rank
        FROM cs_sample c
        JOIN customer cust           ON c.cs_bill_customer_sk = cust.c_customer_sk
        JOIN customer_address ca     ON c.cs_bill_addr_sk = ca.ca_address_sk
        JOIN promotion promo         ON c.cs_promo_sk = promo.p_promo_sk
        JOIN ship_mode sm            ON c.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE c.cs_sold_date_sk BETWEEN 2451910 AND 2451915
          AND c.cs_quantity > 1
          AND c.cs_net_paid > 100
          AND ca.ca_country = 'United States'
    ),
    /* Union of the three star‑shaped parts */
    combined AS (
        SELECT * FROM store_part
        UNION
        SELECT * FROM web_part
        UNION
        SELECT * FROM catalog_part
    ),
    /* Rows to be excluded – negative‑profit rows from the combined set */
    exclude_set AS (
        SELECT sold_date_sk, customer_id, state, promo_id, net_paid, net_profit, profit_flag, total_return_amt, promo_sales_rank
        FROM combined
        WHERE profit_flag = 'NEG'
    )
SELECT
    sold_date_sk,
    customer_id,
    state,
    promo_id,
    net_paid,
    net_profit,
    profit_flag,
    total_return_amt,
    promo_sales_rank
FROM combined
EXCEPT
SELECT * FROM exclude_set
ORDER BY sold_date_sk NULLS LAST, net_paid DESC
LIMIT 100

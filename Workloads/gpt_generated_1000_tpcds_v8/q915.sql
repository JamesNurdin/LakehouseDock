WITH union_data AS (
    SELECT
        ss.ss_item_sk                AS item_sk,
        ss.ss_customer_sk            AS customer_sk,
        ss.ss_cdemo_sk               AS cdemo_sk,
        ss.ss_addr_sk                AS addr_sk,
        ss.ss_promo_sk               AS promo_sk,
        ss.ss_ticket_number          AS ticket_number,
        ss.ss_quantity               AS qty,
        ss.ss_net_paid               AS net_paid,
        ss.ss_ext_discount_amt       AS discount_amt,
        CAST(NULL AS integer)        AS reason_sk,
        CAST(NULL AS decimal(7,2))  AS return_amt
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000

    UNION

    SELECT
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        CAST(NULL AS integer),
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        CAST(NULL AS decimal(7,2)),
        CAST(NULL AS decimal(7,2)),
        sr.sr_reason_sk,
        sr.sr_return_amt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2455000
),
filtered AS (
    SELECT *
    FROM union_data ud
    WHERE EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = ud.item_sk
              AND sr2.sr_return_amt > 0
              AND sr2.sr_customer_sk = ud.customer_sk
        )
      AND ud.item_sk IN (
            SELECT i3.i_item_sk FROM item i3 WHERE i3.i_units = 'Ounce'
            INTERSECT
            SELECT i4.i_item_sk FROM item i4 WHERE i4.i_manufact_id = 625
        )
),
joined AS (
    SELECT
        i1.i_category,
        i2.i_brand,
        ca.ca_state,
        cd.cd_gender,
        p1.p_promo_name,
        ud.net_paid,
        ud.return_amt,
        ud.ticket_number,
        ud.customer_sk,
        ud.item_sk
    FROM filtered ud
    JOIN item i1 ON ud.item_sk = i1.i_item_sk                                    -- store_sales.ss_item_sk = item.i_item_sk
    JOIN promotion p1 ON ud.promo_sk = p1.p_promo_sk                               -- store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN item i2 ON p1.p_item_sk = i2.i_item_sk                                   -- promotion.p_item_sk = item.i_item_sk
    JOIN promotion p2 ON p2.p_item_sk = i2.i_item_sk AND p2.p_promo_sk <> p1.p_promo_sk
    JOIN customer_address ca ON ud.addr_sk = ca.ca_address_sk                     -- store_sales.ss_addr_sk = customer_address.ca_address_sk
    JOIN customer_demographics cd ON ud.cdemo_sk = cd.cd_demo_sk                  -- store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN reason r ON ud.reason_sk = r.r_reason_sk                            -- store_returns.sr_reason_sk = reason.r_reason_sk
    JOIN store_sales ss ON ud.ticket_number = ss.ss_ticket_number                -- store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number           -- store_returns.sr_ticket_number = store_sales.ss_ticket_number
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        ca_state,
        cd_gender,
        p_promo_name,
        SUM(net_paid)   AS total_net_paid,
        SUM(return_amt) AS total_return_amt,
        COUNT(DISTINCT ticket_number) AS tickets
    FROM joined
    GROUP BY CUBE(i_category, i_brand, ca_state, cd_gender, p_promo_name)
)
SELECT
    i_category,
    i_brand,
    ca_state,
    cd_gender,
    p_promo_name,
    total_net_paid,
    total_return_amt,
    tickets,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC)            AS state_rank,
    SUM(total_net_paid) OVER (PARTITION BY i_category ORDER BY total_net_paid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
